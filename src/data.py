import numpy as np
import pandas as pd

def load_data(data_path):
    """
    loads data in data_path csv into two numpy arrays:
    features (NxK) and labels (Nx1) 
    where N = number of rows, K = number of features.

    Args:
        data_path (str): path to csv file containing the data

    Output:
        features (np.array): NxK containing K features
        labels (np.array): 1xN containing N labels.
        attribute_names (list): list of strings containing names of each attribute
            (headers of csv)
    """
    if data_path.endswith('gz'):
        df = pd.read_csv(data_path, compression='gzip')
    else:
        df = pd.read_csv(data_path)

    feature_columns = [col for col in df.columns if col != "class"]
    features = df[feature_columns].to_numpy()
    label = df[["class"]].to_numpy()

    return features, label, feature_columns


def train_test_split(features, labels, fraction):
    """
    Split features and labels into training and testing. The first M points
    from the data will be used for training and the remaining
    (features.shape[0] - M) points will be used for testing. Where M is:

        M = int(features.shape[0] * fraction)

    when fraction is 1.0, both training and test splits are
    the entire dataset

    Args:
        features (np.array): NxD numpy array containing D features for each example
        labels (np.array): Nx1 numpy array containing labels corresponding to each example
        fraction (float between 0.0 and 1.0): fraction of examples to be drawn for training

    Returns (a tuple containing four variables):
        train_features: MxD numpy array of examples to be used for training
        train_labels: Mx1 numpy array of labels corresponding to `train_features`
        test_features: (N - M)xD numpy array of examples to be used for testing
        test_labels: (N - M)x1 numpy array of labels corresponding to `test_features`
    """

    if fraction == 1.0:
        return features, labels, features, labels
    elif fraction < 1.0:

        M = int(features.shape[0] * fraction)
        train_features = features[:M]
        train_labels = labels[:M]
        test_features = features[M:]
        test_labels = labels[M:]
        
        return train_features, train_labels, test_features, test_labels
    else:
        raise ValueError('fraction must be less than or equal to 1.0!')

def cross_validation(features, labels, n_folds):
    """
    Split the data in `n_folds` different groups for cross-validation.
        Split the features and labels into a `n_folds` number of groups that
        divide the data as evenly as possible. Then for each group,
        return a tuple that treats that group as the test set and all
        other groups combine to make the training set.

    Args:
        features: an NxK matrix of N examples, each with K features
        labels: an Nx1 array of N labels
        n_folds: the number of cross-validation groups

    Output:
        A list of tuples, where each tuple contains:
          (train_features, train_labels, test_features, test_labels)
    """

    """
    assert features.shape[0] == labels.shape[0]

    if n_folds == 1:
        return [(features, labels, features, labels)]
    
    # otherwise continue... 
    sample_size = features.shape[0]
    fold_size = sample_size // n_folds
    #leftover = sample_size % n_folds

    for i in range(n_folds):
        fold_indices = [fold_size * (i + 1)]
    splits = []
    """

    assert features.shape[0] == labels.shape[0]

    if n_folds == 1:
        return [(features, labels, features, labels)]
    
    sample_size = features.shape[0]
    fold_size = sample_size // n_folds

    splits = []

    for i in range(n_folds):
        test_start = i * fold_size
        test_end = (i + 1) * fold_size

        test_features = features[test_start:test_end]
        test_labels = labels[test_start:test_end]

        train_features = np.concatenate([features[:test_start], features[test_end:]], axis=0)
        train_labels = np.concatenate([labels[:test_start], labels[test_end:]], axis=0)

        splits.append((train_features, train_labels, test_features, test_labels))

    return splits