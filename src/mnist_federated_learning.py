from stat import filemode

import tensorflow as tf
import numpy as np
import logging

# 1] Uploading MNIST dataset as a numpy array ---------------------------------------------------------------

(x_train, y_train), (x_test, y_test) = tf.keras.datasets.mnist.load_data(
    path='mnist.npz'
)

# mapping function
def normalize_img(image, label):
  """Normalizes images: `uint8` -> `float32`."""
  return tf.cast(image, tf.float32) / 255., label

# Index shuffle
#indices = np.random.permutation(len(x_train))
# Applying shuffle to both numpy arrays
#(x_train_shuffled, y_train_shuffled) = (x_train[indices], y_train[indices])

# Turning test numpy array into a tf.data.datasets
ds_test =  tf.data.Dataset.from_tensor_slices((x_test, y_test))

# building a test pipeline --------------------------------------------------------------------------

ds_test = ds_test.map(
    normalize_img, num_parallel_calls=tf.data.AUTOTUNE)
ds_test = ds_test.batch(128)
ds_test = ds_test.cache()
#ds_test = ds_test.prefetch(tf.data.AUTOTUNE)

# 2] Partitioning dataset into K, data Partitions Pk, one for each client ----------------------------------------

# TO KNOW : x_train is a numpy array, which in the MNIST case consists of a 3D tensor, made up of 60.000 images
# of 28x28 pixels

num_clients = 12
client_dataset = []
split_size = len(x_train) // num_clients

# 3] Creating client model --------------------------------------------------------------------------------------

# TO KNOW :

# We'll have two models used for decentralized training on clients and a server model where we
# aggregate and average all parameters given by clients

client_model_1 = tf.keras.models.Sequential([
  tf.keras.layers.Flatten(input_shape=(28, 28)),
  tf.keras.layers.Dense(128, activation='relu'),
  tf.keras.layers.Dense(10)
])

client_model_2 = tf.keras.models.Sequential([
  tf.keras.layers.Flatten(input_shape=(28, 28)),
  tf.keras.layers.Dense(128, activation='relu'),
  tf.keras.layers.Dense(10)
])

# compiling model --> optimization function, loss function and metrics ( to observe during tests )
client_model_1.compile(
    optimizer=tf.keras.optimizers.Adam(0.001),
    loss=tf.keras.losses.SparseCategoricalCrossentropy(from_logits=True),
    metrics=[tf.keras.metrics.SparseCategoricalAccuracy()],
)

client_model_2.compile(
    optimizer=tf.keras.optimizers.Adam(0.001),
    loss=tf.keras.losses.SparseCategoricalCrossentropy(from_logits=True),
    metrics=[tf.keras.metrics.SparseCategoricalAccuracy()],
)

# 4] Creating server model --------------------------------------------------------------------------------------

server_model = tf.keras.models.Sequential([
  tf.keras.layers.Flatten(input_shape=(28, 28)),
  tf.keras.layers.Dense(128, activation='relu'),
  tf.keras.layers.Dense(10)
])

# compiling model --> optimization function, loss function and metrics ( to observe during tests )
server_model.compile(
    optimizer=tf.keras.optimizers.Adam(0.001),
    loss=tf.keras.losses.SparseCategoricalCrossentropy(from_logits=True),
    metrics=[tf.keras.metrics.SparseCategoricalAccuracy()],
)


# log file configuration
logging.basicConfig(
    filename='model.log',
    level=logging.INFO,
    format='%(asctime)s : global model performances update: accuracy= %(message)s; loss= %(message)s',
    filemode='w'
)



for i in range(num_clients):
    start = i * split_size
    if i != num_clients - 1 :
        end = (i + 1) * split_size
    else :
        end = len(x_train)

    # 5] Turning dataset into a tf.Dataset ------------------------------------------------------------------------
    dataset = tf.data.Dataset.from_tensor_slices((x_train[start:end], y_train[start:end]))

    # changing data format
    ds_train = dataset.map(
        normalize_img, num_parallel_calls=tf.data.AUTOTUNE)

    # caching data before shuffle on client
    ds_train = ds_train.cache()

    # 6] Shuffling dataset
    ds_train = ds_train.shuffle(buffer_size=1000)

    # 7] creating batches -----------------------------------------------------------------------------------------
    ds_train = ds_train.batch(128)
    # prefetching data --> improve dataset's upload efficiency
    ds_train = ds_train.prefetch(tf.data.AUTOTUNE)

    # 8] Iterating more training round ----------------------------------------------------------------------------

    # TO KNOW :
    # for simplicity we assume that each function call corresponds to a client Internet communication

    # Setting current global model weights to clients' model
    server_weights = server_model.get_weights()
    client_model_1.set_weights(server_weights)
    client_model_2.set_weights(server_weights)

    # training and testing the model
    client_model_1.fit(
        ds_train,
        epochs=1,
    )

    client_model_2.fit(
        ds_train,
        epochs=1,
    )

    # 9] At the end of each round, use the new parameters to initialize server model -----------------------------

    client_weights_list = []

    # Collecting new client's model parameters after training
    client_weights_1 = client_model_1.get_weights()
    client_weights_list.append(client_weights_1)
    client_weights_2 = client_model_2.get_weights()
    client_weights_list.append(client_weights_2)


    # 10] Averaging and setting parameters on server model -------------------------------------------------------

    aggregated_weights = []

    # Iterating on each layer
    for layer_idx in range(len(client_weights_list[0])):  # Each client model has the same number of layer
        # Weights of each client for the current layer
        layer_weights = [client_weights[layer_idx] for client_weights in client_weights_list]

        # Averaging weights for the current layer
        aggregated_layer_weights = np.mean(layer_weights, axis=0)
        aggregated_weights.append(aggregated_layer_weights)


    # Setting weights on global model
    server_model.set_weights(aggregated_weights)


    # 11] Evaluating test dataset on server model at the end of each round ---------------------------------------

    # training and testing the global model
    server_model.fit(
        ds_train,
        epochs=1,
        validation_data=ds_test,
    )

    # 12] Logging model performances round after round -----------------------------------------------------------

    loss, accuracy = server_model.evaluate(ds_test, verbose=0)
    logging.info(f"Accuracy: {accuracy}, Loss: {loss}")






