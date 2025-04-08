# 1st Machine Learning Example with Mnist Dataset

import tensorflow as tf
import tensorflow_datasets as tfds

# loading MNIST data set

(ds_train, ds_test), ds_info = tfds.load(
    'mnist',
    split=['train', 'test'],
    shuffle_files=True,
    as_supervised=True,
    with_info=True,
)

# building a training pipeline ------------------------------------------------------------------

# mapping function
def normalize_img(image, label):
  """Normalizes images: `uint8` -> `float32`."""
  return tf.cast(image, tf.float32) / 255., label


# changing data format
ds_train = ds_train.map(
    normalize_img, num_parallel_calls=tf.data.AUTOTUNE)

# caching data before shuffle
ds_train = ds_train.cache()

# shuffling dataset
ds_train = ds_train.shuffle(ds_info.splits['train'].num_examples)

# creating batches
ds_train = ds_train.batch(128)

# prefetching data --> improve dataset's upload efficiency
ds_train = ds_train.prefetch(tf.data.AUTOTUNE)

# building a test pipeline --------------------------------------------------------------------------

ds_test = ds_test.map(
    normalize_img, num_parallel_calls=tf.data.AUTOTUNE)
ds_test = ds_test.batch(128)
ds_test = ds_test.cache()
ds_test = ds_test.prefetch(tf.data.AUTOTUNE)

# keras model ---------------------------------------------------------------------------------------


# creating model
model = tf.keras.models.Sequential([
  tf.keras.layers.Flatten(input_shape=(28, 28)),
  tf.keras.layers.Dense(128, activation='relu'),
  tf.keras.layers.Dense(10)
])

# compiling model --> optimization function, loss function and metrics ( to observe during tests )
model.compile(
    optimizer=tf.keras.optimizers.Adam(0.001),
    loss=tf.keras.losses.SparseCategoricalCrossentropy(from_logits=True),
    metrics=[tf.keras.metrics.SparseCategoricalAccuracy()],
)

# training and testing the model
model.fit(
    ds_train,
    epochs=6,
    validation_data=ds_test,
)