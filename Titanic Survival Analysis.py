"""Titanic Survival Analysis 


# **Key columns:**

*   Survived: Whether the passenger survived (1 = survived, 0 = did not survive)

*   Pclass: Passenger class (1st, 2nd, or 3rd class)

*   Age: Age of the passenger

*   SibSp: Number of siblings/spouses aboard

*   Parch: Number of parents/children aboard

*   Fare: The fare the passenger paid
"""

# Import necessary libraries
import pandas as pd
import numpy as np

# Load the dataset
url = 'https://raw.githubusercontent.com/datasciencedojo/datasets/master/titanic.csv'
data = pd.read_csv(url)

# Display the first few rows
data.head()

# Display the summary statistics before handling missing values
print("\nInitial Dataset Summary:\n", data.describe())

# Check for missing values
missing_values = data.isnull().sum()
print("Missing Values:\n", missing_values)

"""# Handling Missing Values"""

# Deletion method: Drop rows with missing values
data_deletion = data.dropna()

# Summary after deletion
print("\nSummary after Deletion:\n", data_deletion.describe())

# Imputation with mean
numeric_columns = data.select_dtypes(include=np.number).columns
data_mean_imputed = data.copy()
data_mean_imputed[numeric_columns] = data_mean_imputed[numeric_columns].fillna(data_mean_imputed[numeric_columns].mean())

# Summary after mean imputation
print("\nSummary after Mean Imputation:\n", data_mean_imputed.describe())

# Imputation with median
numeric_columns = data.select_dtypes(include=np.number).columns
data_median_imputed = data.copy()
data_median_imputed[numeric_columns] = data_median_imputed[numeric_columns].fillna(data_median_imputed[numeric_columns].median())

# Summary after median imputation
print("\nSummary after Median Imputation:\n", data_median_imputed.describe())

# Imputation with mode
data_mode_imputed = data.fillna(data.mode().iloc[0])

# Summary after mode imputation
print("\nSummary after Mode Imputation:\n", data_mode_imputed.describe())

# Compare the mean, median, and mode imputed datasets
comparison = pd.DataFrame({
    'Original': data.select_dtypes(include=np.number).mean(),
    'After Deletion': data_deletion.select_dtypes(include=np.number).mean(),
    'After Mean Imputation': data_mean_imputed.select_dtypes(include=np.number).mean(),
    'After Median Imputation': data_median_imputed.select_dtypes(include=np.number).mean(),
    'After Mode Imputation': data_mode_imputed.select_dtypes(include=np.number).mean()
})

print("\nComparison of Mean Values Across Methods:\n", comparison)

# Recheck for any remaining missing values
data_deletion.isnull().sum()

# Check for any duplicates
duplicates = data.duplicated().sum()
print(f"Number of duplicates: {duplicates}")

# # Remove duplicates (if any)
data_deletion.drop_duplicates()

# Display data types
print("\nData Types:\n", data_deletion.dtypes)

# # Summary of cleaned data
# print("\nSummary of Cleaned Data:\n", data_cleaned.describe())

"""# Visualization"""

# Set the overall aesthetic of the plots
sns.set(style='whitegrid')

"""1. Count plot for the number of survivors"""

# 1. Count plot for the number of survivors
plt.figure(figsize=(6,4))
sns.countplot(data=titanic_data, x='Survived', palette='viridis')
plt.title('Count of Survivors')
plt.xlabel('Survived (0 = No, 1 = Yes)')
plt.ylabel('Count')
plt.show()

"""2. Distribution of passengers by Class"""

plt.figure(figsize=(8,6))
sns.countplot(data=titanic_data, x='Pclass', hue='Survived', palette='coolwarm')
plt.title('Survival Count by Passenger Class')
plt.xlabel('Passenger Class')
plt.ylabel('Count')
plt.show()

"""*3*. Distribution of Age"""

plt.figure(figsize=(8,6))
sns.histplot(titanic_data['Age'], kde=True, color='blue')
plt.title('Distribution of Passenger Ages')
plt.xlabel('Age')
plt.ylabel('Frequency')
plt.show()

"""4. Survival by Gender"""

plt.figure(figsize=(8,6))
sns.countplot(data=titanic_data, x='Sex', hue='Survived', palette='Set2')
plt.title('Survival Count by Gender')
plt.xlabel('Gender')
plt.ylabel('Count')
plt.show()

"""5. Survival Rate by Age"""

plt.figure(figsize=(8,6))
sns.kdeplot(data=titanic_data[titanic_data['Survived'] == 1], x='Age', color='green', shade=True, label='Survived')
sns.kdeplot(data=titanic_data[titanic_data['Survived'] == 0], x='Age', color='red', shade=True, label='Did Not Survive')
plt.title('Survival Rate by Age')
plt.xlabel('Age')
plt.ylabel('Density')
plt.legend()
plt.show()


# Logistic Regression"""

# Import necessary libraries
from sklearn.model_selection import train_test_split
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import accuracy_score, confusion_matrix, classification_report

# Preprocessing
titanic_data = titanic_data.drop(['Cabin', 'Ticket', 'Name'], axis=1)  # Drop columns with too many missing values
titanic_data['Age'].fillna(titanic_data['Age'].median(), inplace=True)  # Fill missing Age with median
titanic_data['Embarked'].fillna(titanic_data['Embarked'].mode()[0], inplace=True)  # Fill missing Embarked

# Convert categorical variables
titanic_data = pd.get_dummies(titanic_data, columns=['Sex', 'Embarked'], drop_first=True)

# Define features (X) and target (y)
X = titanic_data.drop('Survived', axis=1)
y = titanic_data['Survived']

from sklearn.model_selection import train_test_split

# Split the data into training and test sets
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

# Initialize and train logistic regression model
logreg = LogisticRegression(max_iter=1000)
logreg.fit(X_train, y_train)

# Predict and evaluate the model
y_pred = logreg.predict(X_test)
y_pred_proba = logreg.predict_proba(X_test)[:,1]  # Get probability scores for the positive class (Survived = 1)

"""# Evaluate the Model's Performance"""

# Import necessary functions from sklearn.metrics
from sklearn.metrics import accuracy_score, confusion_matrix, classification_report

accuracy = accuracy_score(y_test, y_pred)
conf_matrix = confusion_matrix(y_test, y_pred)
class_report = classification_report(y_test, y_pred)

print(f"Accuracy: {accuracy * 100:.2f}%")
print("Confusion Matrix:")
print(conf_matrix)
print("Classification Report:")
print(class_report)

"""# Logistic Regression Visualization"""

# Confusion Matrix
conf_matrix = confusion_matrix(y_test, y_pred)
plt.figure(figsize=(6, 4))
sns.heatmap(conf_matrix, annot=True, fmt='d', cmap='Blues', cbar=False, xticklabels=['Did not Survive', 'Survived'], yticklabels=['Did not Survive', 'Survived'])
plt.title('Confusion Matrix')
plt.xlabel('Predicted')
plt.ylabel('Actual')
plt.show()

# ROC Curve
fpr, tpr, _ = roc_curve(y_test, y_pred_proba)
roc_auc = roc_auc_score(y_test, y_pred_proba)

plt.figure(figsize=(8, 6))
plt.plot(fpr, tpr, label=f'Logistic Regression (AUC = {roc_auc:.2f})')
plt.plot([0, 1], [0, 1], 'k--')  # Diagonal line for random guessing
plt.title('ROC Curve')
plt.xlabel('False Positive Rate')
plt.ylabel('True Positive Rate')
plt.legend()
plt.show()

# Precision-Recall Curve
precision, recall, _ = precision_recall_curve(y_test, y_pred_proba)

plt.figure(figsize=(8, 6))
plt.plot(recall, precision, label='Precision-Recall Curve')
plt.title('Precision-Recall Curve')
plt.xlabel('Recall')
plt.ylabel('Precision')
plt.legend()
plt.show()

# Feature Importance (Coefficients)
coefficients = pd.DataFrame(logreg.coef_.T, X.columns, columns=['Coefficient'])
coefficients.sort_values(by='Coefficient', ascending=False, inplace=True)

plt.figure(figsize=(10, 6))
sns.barplot(x=coefficients['Coefficient'], y=coefficients.index)
plt.title('Feature Importance (Logistic Regression Coefficients)')
plt.xlabel('Coefficient Value')
plt.ylabel('Feature')
plt.show()
