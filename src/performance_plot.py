import re
import matplotlib.pyplot as plt

def extract_accuracy_from_log(filename):
    """
    Reads the log file and returns a list of accuracies per round.
    Assumes each line of the file has the format:
       "Accuracy: <accuracy_value>, Loss: <loss_value>"
    """
    accuracies = []
    with open(filename, 'r') as f:
        for line in f:
            match = re.search(r'Accuracy:\s*([0-9.]+)', line)
            if match:
                accuracy = float(match.group(1))
                accuracies.append(accuracy)
    return accuracies

# Extract data from the three log files
iid_log = "IID_model.log"
noniid5_log = "nonIID5_model.log"
noniid2_log = "nonIID2_model.log"

accuracy_iid = extract_accuracy_from_log(iid_log)
accuracy_noniid5 = extract_accuracy_from_log(noniid5_log)
accuracy_noniid2 = extract_accuracy_from_log(noniid2_log)

# Define rounds (1 to 12)
num_rounds = 12
rounds = list(range(1, num_rounds + 1))

# Create the plot with a dark background
plt.style.use('dark_background')
plt.figure(figsize=(8, 6))

# Plot lines with custom colors
plt.plot(rounds, accuracy_iid[:num_rounds], marker='o', color='cyan', label='MNIST Fed Learning IID')
plt.plot(rounds, accuracy_noniid5[:num_rounds], marker='s', color='magenta', label='MNIST Fed Learning non-IID (5 classes)')
plt.plot(rounds, accuracy_noniid2[:num_rounds], marker='^', color='yellow', label='MNIST Fed Learning non-IID (2 classes)')

# Labels, title and formatting
plt.title("Test Accuracy in Federated Learning with MNIST")
plt.xlabel("Round")
plt.ylabel("Test Accuracy")
plt.ylim([0, 1])
plt.xticks(rounds)
plt.legend()
plt.grid(True, linestyle='--', alpha=0.3)

# Show the plot
plt.show()

# Saving the plot
plt.savefig("federated_accuracy.png")