import torch
import torch.nn as nn
import torch.optim as optim
import numpy as np
from torch.utils.data import DataLoader, TensorDataset
import pandas as pd
import matplotlib.pyplot as plt
from sklearn.preprocessing import StandardScaler,LabelEncoder
from torch.utils.data import random_split

class VAE(nn.Module):
    def __init__(self, input_dim, hidden_dim, latent_dim):
        super(VAE, self).__init__()
        
        # Encoder
        self.encoder = nn.Sequential(
            nn.Linear(input_dim, hidden_dim),
            nn.ReLU(),
            nn.Linear(hidden_dim, hidden_dim),
            nn.ReLU()
        )
        
        # Latent space layers
        self.fc_mu = nn.Linear(hidden_dim, latent_dim)
        self.fc_var = nn.Linear(hidden_dim, latent_dim)
        
        # Decoder
        self.decoder = nn.Sequential(
            nn.Linear(latent_dim, hidden_dim),
            nn.ReLU(),
            nn.Linear(hidden_dim, hidden_dim),
            nn.ReLU(),
            nn.Linear(hidden_dim, input_dim)
        )
    
    def reparameterize(self, mu, log_var):
        """
        Reparameterization trick to sample from N(mu, var)
        """
        std = torch.exp(0.5 * log_var)
        eps = torch.randn_like(std)
        return mu + eps * std
    
    def forward(self, x):
        # Encode
        h = self.encoder(x)
        
        # Get mu and log variance
        mu = self.fc_mu(h)
        log_var = self.fc_var(h)
        
        # Reparameterize
        z = self.reparameterize(mu, log_var)
        
        # Decode
        x_recon = self.decoder(z)
        
        return x_recon, mu, log_var

class VAEClassifier(nn.Module):
    def __init__(self, vae, num_classes):
        super(VAEClassifier, self).__init__()
        
        # Freeze VAE parameters
        for param in vae.parameters():
            param.requires_grad = False
        
        self.vae = vae
        
        # Classification layers
        self.classifier = nn.Sequential(
            nn.Linear(vae.fc_mu.out_features, 32),
            nn.ReLU(),
            nn.Linear(32, num_classes)
        )
    
    def forward(self, x):
        # Get latent representation through VAE
        h = self.vae.encoder(x)
        mu = self.vae.fc_mu(h)
        # Classify
        return self.classifier(mu)

def vae_loss(recon_x, x, mu, log_var):
    """
    VAE Loss function:
    Reconstruction Loss + KL Divergence
    """
    # Reconstruction loss
    recon_loss = nn.functional.mse_loss(recon_x, x, reduction='sum')
    
    # KL Divergence loss
    kl_loss = -0.5 * torch.sum(1 + log_var - mu.pow(2) - log_var.exp())
    
    return recon_loss + kl_loss

def train_vae(model, train_loader, optimizer, device):
    model.train()
    total_loss = 0
    
    for batch in train_loader:
        if len(batch) == 1:  # If it's the normal data
            x = batch[0].to(device)
        else:  # If it's the full data with labels
            x, _ = batch  # Ignore the labels for the VAE
            x = x.to(device)
        
        optimizer.zero_grad()
        
        # Forward pass
        x_recon, mu, log_var = model(x)
        
        # Compute loss
        loss = vae_loss(x_recon, x, mu, log_var)
        
        # Backward pass
        loss.backward()
        optimizer.step()
        
        total_loss += loss.item()
    
    return total_loss / len(train_loader)

def train_classifier(model, train_loader, optimizer, criterion, device):
    model.train()
    total_loss = 0
    
    for batch, labels in train_loader:
        batch, labels = batch.to(device), labels.to(device)
        
        optimizer.zero_grad()
        
        # Forward pass
        outputs = model(batch)
        
        # Compute loss
        loss = criterion(outputs, labels)
        
        # Backward pass
        loss.backward()
        optimizer.step()
        
        total_loss += loss.item()
    
    return total_loss / len(train_loader)

def main():
    # Hyperparameters
    input_dim = 8  # Adjust based on your dataset
    hidden_dim = 128
    latent_dim = 64
    num_classes = 6
    learning_rate = 5*1e-5
    epochs_vae = 1000
    epochs_classifier = 200
    
    # Device configuration
    device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
    
    df = pd.read_csv('Dataset/predictive_maintenance.csv')
    
    #deleting unlogical data
    df_failure = df[df['Target'] == 1]
    df_failure[df_failure['Failure Type'] == 'No Failure']
    index_possible_failure = df_failure[df_failure['Failure Type'] == 'No Failure'].index
    df.drop(index_possible_failure, axis=0, inplace=True)
    
    df.drop(["UDI", "Product ID"], axis=1, inplace=True)
    df = pd.get_dummies(df, columns=['Type'], prefix='', prefix_sep='', drop_first=False)
    
    dummy_columns = [col for col in df.columns if col in ['H', 'L', 'M']]  # Adjust based on your specific column names
    df[dummy_columns] = df[dummy_columns].astype(float)
        
    feature_columns = ['Air temperature [K]', 'Process temperature [K]', 'Rotational speed [rpm]', 'Torque [Nm]', 'Tool wear [min]', 'H', 'L', 'M']
    normal_behaviour_data = df[df['Target']==0]
    print(normal_behaviour_data.head(5))
    
    X = normal_behaviour_data[feature_columns].values
    
    
    scaler = StandardScaler()
    X = scaler.fit_transform(X)
    
    # Prepare your dataset (example)
    # Replace this with your actual data loading
    X_normal = torch.tensor(X, dtype=torch.float32)  # Normal behavior data
    
    x_full = df[feature_columns].values
    X_full = torch.tensor(x_full, dtype=torch.float32)    # Full dataset
    
    # Initialize the encoder
    label_encoder = LabelEncoder()

    # Fit and transform the 'Failure Type' column
    df['Failure Type Encoded'] = label_encoder.fit_transform(df['Failure Type'])
    import pickle

    with open('label_encoder.pkl', 'wb') as f:
        pickle.dump(label_encoder, f)
    print(label_encoder.classes_)

    y_labels = torch.tensor(df['Failure Type Encoded'].values, dtype=torch.long)
    
    # Create DataLoaders
    normal_dataset = TensorDataset(X_normal)
    
    
    normal_loader = DataLoader(normal_dataset, batch_size=8, shuffle=True)
    import os
    
    
    # Initialize VAE
    vae = VAE(input_dim, hidden_dim, latent_dim).to(device)
    vae_optimizer = optim.Adam(vae.parameters(), lr=learning_rate)
    
    # Train VAE on normal data
    print("Training VAE...")
    for epoch in range(epochs_vae):
        loss = train_vae(vae, normal_loader, vae_optimizer, device)
        print(f"Epoch [{epoch+1}/{epochs_vae}], Loss: {loss:.4f}")
    
    # Save VAE model
    torch.save(vae.state_dict(), 'Models\vae_model.pth')

    full_dataset = TensorDataset(X_full, y_labels)
    # Set the proportions for train and validation splits
    train_size = int(0.9 * len(full_dataset))
    val_size = len(full_dataset) - train_size

    # Split the dataset
    train_dataset, val_dataset = random_split(full_dataset, [train_size, val_size])

    # Create DataLoaders
    train_loader = DataLoader(train_dataset, batch_size=8, shuffle=True)
    val_loader = DataLoader(val_dataset, batch_size=8, shuffle=False)
    
    # Create Classifier
    classifier = VAEClassifier(vae, num_classes).to(device)
    classifier_optimizer = optim.Adam(classifier.parameters(), lr=learning_rate)
    criterion = nn.CrossEntropyLoss()
    
    
    

    train_losses = []
    val_losses = []
    val_accuracies = []
    # Train Classifier
    print("\nTraining Classifier...")
    for epoch in range(epochs_classifier):
        train_loss = train_classifier(classifier, train_loader, classifier_optimizer, criterion, device)
        train_losses.append(train_loss) 
               
        # Evaluate on the validation set
        classifier.eval()  # Set the model to evaluation mode
        val_loss = 0
        correct = 0
        total = 0
        with torch.no_grad():
            for batch, labels in val_loader:
                batch, labels = batch.to(device), labels.to(device)
                # Forward pass
                outputs = classifier(batch)
                # Compute validation loss
                val_loss += criterion(outputs, labels).item()
                    
                                # Calculate accuracy
                _, predicted = torch.max(outputs, 1)
                correct += (predicted == labels).sum().item()
                total += labels.size(0)
        val_loss /= len(val_loader)
        val_losses.append(val_loss)

        val_accuracy = 100 * correct / total
        val_accuracies.append(val_accuracy)

        # Print epoch stats
        print(f"Epoch [{epoch+1}/{epochs_classifier}], Train Loss: {train_loss:.4f}, Val Loss: {val_loss:.4f}, Val Accuracy: {val_accuracy:.2f}%")
    # Save Classifier
    torch.save(classifier.state_dict(), 'Models\classifier_model.pth')
    
    # Plot training and validation loss
    plt.figure(figsize=(10, 5))
    plt.plot(range(1, epochs_classifier + 1), train_losses, label='Train Loss')
    plt.plot(range(1, epochs_classifier + 1), val_losses, label='Validation Loss')
    plt.xlabel('Epoch')
    plt.ylabel('Loss')
    plt.title('Loss Variation Over Epochs')
    plt.legend()
    plt.grid()
    # Save the figure
    plt.savefig('Results\loss_variation.png', dpi=300)  # Specify the file name and DPI for quality
    plt.show()
    
    # Plot Validation Accuracy
    plt.figure(figsize=(10, 5))
    plt.plot(range(1, epochs_classifier + 1), val_accuracies, label='Validation Accuracy')
    plt.xlabel('Epoch')
    plt.ylabel('Accuracy (%)')
    plt.title('Validation Accuracy Over Epochs')
    plt.legend()
    plt.grid()
    # Save the figure
    plt.savefig('Results\accuracy_variation.png', dpi=300)
    plt.show()
 
    


if __name__ == "__main__":
    main()