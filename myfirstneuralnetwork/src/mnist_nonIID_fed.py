# Federated Learning with Mnist Dataset and Non-IID data distribution

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
indices = np.random.permutation(len(x_train))
# Applying shuffle to both numpy arrays
(x_train_shuffled, y_train_shuffled) = (x_train[indices], y_train[indices])

# Turning test numpy array into a tf.data.datasets
ds_test =  tf.data.Dataset.from_tensor_slices((x_test, y_test))

# building a test pipeline --------------------------------------------------------------------------

ds_test = ds_test.map(
    normalize_img, num_parallel_calls=tf.data.AUTOTUNE)
ds_test = ds_test.batch(64)
ds_test = ds_test.cache()
#ds_test = ds_test.prefetch(tf.data.AUTOTUNE)

# 2] Partitioning dataset into K, data Partitions Pk, one for each client ----------------------------------------

# TO KNOW : x_train is a numpy array, which in the MNIST case consists of a 3D tensor, made up of 60.000 images
# of 28x28 pixels

# configuration parameters
num_rounds = 12
num_clients = 10
num_classes = 10
num_classes_per_client = 2

# dividing training example indices per classes
class_indices = {i: np.where(y_train_shuffled == i)[0] for i in range(num_classes)}
all_classes = np.arange(num_classes)
clients_model = []
split_size = len(x_train) // num_clients
data_per_class = split_size // num_classes_per_client
remaining_data = split_size - data_per_class*num_classes_per_client

# 3] Creating client model --------------------------------------------------------------------------------------

# TO KNOW :

# We'll have two models used for decentralized training on clients and a server model where we
# aggregate and average all parameters given by clients


for cl in range(num_clients) :

    clients_model.append(tf.keras.models.Sequential([
      tf.keras.layers.Flatten(input_shape=(28, 28)),
      tf.keras.layers.Dense(128, activation='relu'),
      tf.keras.layers.Dense(10)
    ]))

    # compiling model --> optimization function, loss function and metrics ( to observe during tests )
    clients_model[cl].compile(
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
    filename='nonIID' + str(num_classes_per_client) + '_model.log',
    level=logging.INFO,
    format='%(asctime)s : global model performances update: %(message)s',
    filemode='w'
)



for i in range(num_rounds):

    # Randomly choosing classes for each client, so that each client is assigned to different classes
    chosen_classes = {k : [] for k in range(num_clients)}
    # dict which contains each client's data
    clients_data_x = {i: np.empty((0, 28, 28)) for i in range(num_clients)}
    clients_data_y = {i: np.empty((0, 28, 28)) for i in range(num_clients)}
    # array containing each client's dataset
    clients_dataset = []

    for client in range(num_clients):

        # Overlapping classes random selection
        chosen_classes[client] = np.random.choice(all_classes, num_classes_per_client, replace=False)

        cl_data_x = []
        cl_data_y = []

        for j in range(num_classes_per_client):
            if j == num_classes_per_client-1:
                cls_indices = class_indices[chosen_classes[client][j]]
                # Random subset of indices of the selected class
                selected = np.random.choice(cls_indices, size=(data_per_class+remaining_data), replace=False)
                for index in selected:
                    cl_data_x.append(x_train_shuffled[index])
                # Creating numpy array with labels for training
                for _ in range(data_per_class + remaining_data) :
                    cl_data_y.append(chosen_classes[client][j])
            else :
                cls_indices = class_indices[chosen_classes[client][j]]
                # Random subset of indices of the selected class
                selected = np.random.choice(cls_indices, size=data_per_class, replace=False)
                for index in selected:
                    cl_data_x.append(x_train_shuffled[index])
                # Creating numpy array with labels for training
                for _ in range(data_per_class) :
                    cl_data_y.append(chosen_classes[client][j])

        clients_data_x[client] = np.array(cl_data_x)
        clients_data_y[client] = np.array(cl_data_y)

        # 5] Turning dataset into a tf.Dataset ------------------------------------------------------------------------
        clients_dataset.append(tf.data.Dataset.from_tensor_slices((clients_data_x[client], clients_data_y[client])))

        # changing data format
        clients_dataset[client] = clients_dataset[client].map(
            normalize_img, num_parallel_calls=tf.data.AUTOTUNE)

        # caching data before shuffle on client
        clients_dataset[client] = clients_dataset[client].cache()

        # 6] Shuffling dataset
        clients_dataset[client] = clients_dataset[client].shuffle(buffer_size=1000)

        # 7] creating batches -----------------------------------------------------------------------------------------
        clients_dataset[client] = clients_dataset[client].batch(64)
        # prefetching data --> improve dataset's upload efficiency
        clients_dataset[client] = clients_dataset[client].prefetch(tf.data.AUTOTUNE)

    # 8] Iterating more training round ----------------------------------------------------------------------------

        # TO KNOW :
        # for simplicity we assume that each function call corresponds to a client Internet communication

        # Setting current global model weights to clients' model
        server_weights = server_model.get_weights()
        clients_model[client].set_weights(server_weights)

        # training and testing the model
        clients_model[client].fit(
            clients_dataset[client],
            epochs=1,
        )

    # 9] At the end of each round, use the new parameters to initialize server model -----------------------------

    client_weights_list = []

    # Collecting new client's model parameters after training
    for client in range(num_clients):
        client_weights = clients_model[client].get_weights()
        client_weights_list.append(client_weights)

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

    # 11] Logging model performances round after round -----------------------------------------------------------

    loss, accuracy = server_model.evaluate(ds_test, verbose=0)
    logging.info(f"Accuracy: {accuracy}, Loss: {loss}")






