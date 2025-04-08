# federated_learning
Private repository where I store practical experiments for my Unibo internship on Federated Learning
Each Federated Learning case was made by iterating 10 rounds of communication between the server model and 10 clients


### FED-LEARNING IID
The first Federated Learning case is based on the MNIST Dataset and IID data distribution :
  Each client receives an amount of data equal to len(dataset) / num_clients


### FED-LEARNING non-IID 5-CLS
The second Federated Learning case is based on the MNIST Dataset and non-IID data distribution :
  Each client receives an amount of data equal to len(dataset) / num_clients, but this time the images of the train set are chosen among only 5 different classes


### FED-LEARNING non-IID 2-CLS
The third Federated Learning case is based on the MNIST Dataset and non-IID data distribution :
  Each client receives an amount of data equal to len(dataset) / num_clients, but this time the images of the train set are chosen among only 2 different classes
