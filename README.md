# federated_learning
Private repository where I store practical experiments for my Unibo internship on Federated Learning
Each Federated Learning case was made by iterating 10 rounds of communication between the server model and 10 clients

---


### FED-LEARNING IID
The first Federated Learning case is based on the MNIST Dataset and IID data distribution :
  Each client receives an amount of data equal to len(dataset) / num_clients

<h3 align="center">Log di Debug</h3>

<p align="center">
  <code>
    2025-04-08 11:48:52,246 : global model performances update: Accuracy: 0.9000999927520752, Loss: 0.3813776969909668
    2025-04-08 11:48:54,583 : global model performances update: Accuracy: 0.9193000197410583, Loss: 0.2918873131275177
    2025-04-08 11:48:56,941 : global model performances update: Accuracy: 0.9294999837875366, Loss: 0.2527235150337219
    2025-04-08 11:48:59,301 : global model performances update: Accuracy: 0.9340000152587891, Loss: 0.2277502417564392
    2025-04-08 11:49:01,634 : global model performances update: Accuracy: 0.9399999976158142, Loss: 0.20873098075389862
    2025-04-08 11:49:03,975 : global model performances update: Accuracy: 0.9448000192642212, Loss: 0.1928132325410843
    2025-04-08 11:49:06,295 : global model performances update: Accuracy: 0.9484000205993652, Loss: 0.17991290986537933
    2025-04-08 11:49:08,643 : global model performances update: Accuracy: 0.9516000151634216, Loss: 0.1689741164445877
    2025-04-08 11:49:10,978 : global model performances update: Accuracy: 0.9531999826431274, Loss: 0.16063079237937927
    2025-04-08 11:49:13,376 : global model performances update: Accuracy: 0.9555000066757202, Loss: 0.15282632410526276
    2025-04-08 11:49:15,705 : global model performances update: Accuracy: 0.9570000171661377, Loss: 0.14465154707431793
    2025-04-08 11:49:18,053 : global model performances update: Accuracy: 0.9588000178337097, Loss: 0.13891543447971344
  </code>
</p>


[log file](/src/IID_model.log)

---


### FED-LEARNING non-IID 5-CLS
The second Federated Learning case is based on the MNIST Dataset and non-IID data distribution :
  Each client receives an amount of data equal to len(dataset) / num_clients, but this time the images of the train set are chosen among only 5 different classes


<h3 align="center">Log di Debug</h3>

<p align="center">
  <code>
    2025-04-08 12:01:49,635 : global model performances update: Accuracy: 0.4611999988555908, Loss: 1.7791693210601807
    2025-04-08 12:01:52,216 : global model performances update: Accuracy: 0.6703000068664551, Loss: 1.1388684511184692
    2025-04-08 12:01:54,778 : global model performances update: Accuracy: 0.760699987411499, Loss: 0.7965793013572693
    2025-04-08 12:01:57,397 : global model performances update: Accuracy: 0.79830002784729, Loss: 0.6369057893753052
    2025-04-08 12:01:59,967 : global model performances update: Accuracy: 0.880299985408783, Loss: 0.4530635178089142
    2025-04-08 12:02:02,661 : global model performances update: Accuracy: 0.8815000057220459, Loss: 0.4205051362514496
    2025-04-08 12:02:05,247 : global model performances update: Accuracy: 0.8626999855041504, Loss: 0.4338754415512085
    2025-04-08 12:02:07,967 : global model performances update: Accuracy: 0.8920999765396118, Loss: 0.34460049867630005
    2025-04-08 12:02:10,729 : global model performances update: Accuracy: 0.8981000185012817, Loss: 0.350240021944046
    2025-04-08 12:02:13,537 : global model performances update: Accuracy: 0.9146999716758728, Loss: 0.3013421893119812
    2025-04-08 12:02:16,167 : global model performances update: Accuracy: 0.921999990940094, Loss: 0.2810606062412262
    2025-04-08 12:02:18,895 : global model performances update: Accuracy: 0.9318000078201294, Loss: 0.24879297614097595
  </code>
</p>

[log file](/src/nonIID5_model.log)


---


### FED-LEARNING non-IID 2-CLS
The third Federated Learning case is based on the MNIST Dataset and non-IID data distribution :
  Each client receives an amount of data equal to len(dataset) / num_clients, but this time the images of the train set are chosen among only 2 different classes


<h3 align="center">Log di Debug</h3>

<p align="center">
  <code>
    2025-04-08 12:05:08,300 : global model performances update: Accuracy: 0.367900013923645, Loss: 2.019132614135742
    2025-04-08 12:05:10,876 : global model performances update: Accuracy: 0.2881999909877777, Loss: 1.8431328535079956
    2025-04-08 12:05:13,451 : global model performances update: Accuracy: 0.44510000944137573, Loss: 1.5002703666687012
    2025-04-08 12:05:16,094 : global model performances update: Accuracy: 0.6129999756813049, Loss: 1.2307716608047485
    2025-04-08 12:05:18,660 : global model performances update: Accuracy: 0.7045999765396118, Loss: 1.0211468935012817
    2025-04-08 12:05:21,294 : global model performances update: Accuracy: 0.7663999795913696, Loss: 0.7944796681404114
    2025-04-08 12:05:23,909 : global model performances update: Accuracy: 0.620199978351593, Loss: 1.0406486988067627
    2025-04-08 12:05:26,530 : global model performances update: Accuracy: 0.7222999930381775, Loss: 0.8341202139854431
    2025-04-08 12:05:29,134 : global model performances update: Accuracy: 0.760200023651123, Loss: 0.7496352791786194
    2025-04-08 12:05:31,738 : global model performances update: Accuracy: 0.7717000246047974, Loss: 0.6643484830856323
    2025-04-08 12:05:34,400 : global model performances update: Accuracy: 0.8366000056266785, Loss: 0.537316620349884
    2025-04-08 12:05:37,027 : global model performances update: Accuracy: 0.8619999885559082, Loss: 0.4866500496864319
  </code>
</p>

[log file](/src/nonIID2_model.log)


---


### PERFORMANCE-COMPARISON

Here we will plot accuracy test results for each of the three experiments.
As we can immediately see from the plot, when we use a non-IID data distribution among clients, the global model improves slowly and in a worse way with respect to the case of IID data distribution


![img_not_found](/images/federated_accuracy.png)


