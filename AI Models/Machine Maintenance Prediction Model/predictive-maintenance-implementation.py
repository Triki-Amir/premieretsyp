import os
import pickle
import numpy as np
import pandas as pd
import torch
import torch.nn as nn
from sklearn.preprocessing import StandardScaler, LabelEncoder

class VAE(nn.Module):
    """Variational Autoencoder (VAE) for feature learning"""
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
    """Classifier that uses VAE's latent representation"""
    def __init__(self, vae, num_classes):
        super(VAEClassifier, self).__init__()
        
        # Freeze VAE parameters
        for param in vae.parameters():
            param.requires_grad = False
        
        self.vae = vae
        
        # Classification layers
        self.classifier = nn.Sequential(
            nn.Linear(vae.fc_mu.out_features, 64),
            nn.ReLU(),
            nn.Linear(64, num_classes)
        )
    
    def forward(self, x):
        # Get latent representation through VAE
        h = self.vae.encoder(x)
        mu = self.vae.fc_mu(h)
        
        # Classify
        return self.classifier(mu)

class PredictiveMaintenance:
    def __init__(self, models_dir='Models'):
        """
        Initialize the Predictive Maintenance Model
        
        Args:
            models_dir (str): Directory containing saved models and preprocessing artifacts
        """
        # Device configuration
        self.device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
        
        # Model hyperparameters (should match training configuration)
        self.input_dim = 8
        self.hidden_dim = 128
        self.latent_dim = 64
        self.num_classes = 6
        
        # Load preprocessing artifacts
        self.load_preprocessing_artifacts(models_dir)
        
        # Initialize and load models
        self.load_models(models_dir)
    
    def load_preprocessing_artifacts(self, models_dir):
        """
        Load saved preprocessing artifacts
        
        Args:
            models_dir (str): Directory containing saved preprocessing artifacts
        """
        # Load StandardScaler
        scaler_path = os.path.join(models_dir, 'scaler.pkl')
        if os.path.exists(scaler_path):
            with open(scaler_path, 'rb') as f:
                self.scaler = pickle.load(f)
        else:
            self.scaler = StandardScaler()
        # Load LabelEncoder
        label_encoder_path = os.path.join(models_dir, 'label_encoder.pkl')
        if os.path.exists(label_encoder_path):
            with open(label_encoder_path, 'rb') as f:
                self.label_encoder = pickle.load(f)
        else:
            raise FileNotFoundError(f"Label Encoder not found at {label_encoder_path}")
    
    def load_models(self, models_dir):
        """
        Load pre-trained VAE and Classifier models
        
        Args:
            models_dir (str): Directory containing saved model weights
        """
        # Initialize VAE
        self.vae = VAE(self.input_dim, self.hidden_dim, self.latent_dim).to(self.device)
        vae_path = os.path.join(models_dir, 'vae_model.pth')
        if os.path.exists(vae_path):
            self.vae.load_state_dict(torch.load(vae_path, map_location=self.device))
        else:
            raise FileNotFoundError(f"VAE model not found at {vae_path}")
        
        # Initialize Classifier
        self.classifier = VAEClassifier(self.vae, self.num_classes).to(self.device)
        classifier_path = os.path.join(models_dir, 'classifier_model.pth')
        if os.path.exists(classifier_path):
            self.classifier.load_state_dict(torch.load(classifier_path, map_location=self.device))
        else:
            raise FileNotFoundError(f"Classifier model not found at {classifier_path}")
        
        # Set models to evaluation mode
        self.vae.eval()
        self.classifier.eval()
    
    def preprocess_data(self, data):
        """
        Preprocess input data
        
        Args:
            data (pd.DataFrame or np.ndarray): Input data to be preprocessed
        
        Returns:
            torch.Tensor: Preprocessed and scaled data
        """
        
        # Scale the data
        scaled_data = self.scaler.fit_transform(data)
                
        # Convert to PyTorch tensor
        return torch.tensor(scaled_data, dtype=torch.float32).to(self.device)
    
    def predict_anomaly(self, data):
        """
        Predict anomaly type for input data
        
        Args:
            data (pd.DataFrame or np.ndarray): Input data to predict
        
        Returns:
            dict: Prediction results including class, probability, and decoded details
        """
        # Preprocess data
        input_tensor = self.preprocess_data(data)
        
        # Get classifier outputs
        with torch.no_grad():
            outputs = self.classifier(input_tensor)
            probabilities = torch.softmax(outputs, dim=1)
            predicted_class_idx = torch.argmax(outputs, dim=1).cpu().numpy()
        
        # Decode predictions
        predicted_class = self.label_encoder.classes_[predicted_class_idx[0]]
        prediction_prob = probabilities[0, predicted_class_idx[0]].item()
        
        # Optional: Reconstruction for anomaly detection
        with torch.no_grad():
            x_recon, _, _ = self.vae(input_tensor)
            reconstruction_error = nn.functional.mse_loss(x_recon, input_tensor, reduction='none').mean(dim=1).cpu().numpy()
        
        return {
            'predicted_class': predicted_class,
            'probability': prediction_prob,
            'reconstruction_error': reconstruction_error[0]
        }
    
    def batch_predict(self, data):
        """
        Predict anomalies for a batch of data
        
        Args:
            data (pd.DataFrame or np.ndarray): Batch of input data to predict
        
        Returns:
            list: List of prediction results for each input
        """
        # Ensure input is a numpy array
        if isinstance(data, pd.DataFrame):
            feature_columns = ['Air temperature [K]', 'Process temperature [K]', 
                               'Rotational speed [rpm]', 'Torque [Nm]', 
                               'Tool wear [min]', 'H', 'L', 'M']
            data = data[feature_columns].values
        
        return [self.predict_anomaly(sample.reshape(1, -1)) for sample in data]

def main():
    # Example usage
    
    # Initialize the predictive maintenance model
    pm_model = PredictiveMaintenance()
    
    # Load some sample data (replace with your actual data loading)
    sample_data = pd.read_csv('Dataset/predictive_maintenance.csv')
    
    sample_data.drop(["UDI", "Product ID","Target","Failure Type"], axis=1, inplace=True)
    sample_data = pd.get_dummies(sample_data, columns=['Type'], prefix='', prefix_sep='', drop_first=False)
    
    dummy_columns = [col for col in sample_data.columns if col in ['H', 'L', 'M']]  # Adjust based on your specific column names
    sample_data[dummy_columns] = sample_data[dummy_columns].astype(float)
    
    # Predict for a single sample
    single_sample_result = pm_model.predict_anomaly(sample_data.iloc[0:1])
    print("Single Sample Prediction:")
    print(single_sample_result)
    
    # Predict for multiple samples
    batch_results = pm_model.batch_predict(sample_data)
    print("\nBatch Predictions:")
    for i, result in enumerate(batch_results):
        print(f"Sample {i+1}: {result}")


if __name__ == "__main__":
    main()
