from os import environ
import boto3

TAG_KEY = environ.get('TAG_KEY')
TAG_VALUE = environ.get('TAG_VALUE')

sagemaker_client = boto3.client("sagemaker")

def lambda_handler(_event, _context):
    # List all notebook instances
    response = sagemaker_client.list_notebook_instances()
    
    print("🔍 Searching for Notebooks to stop")
    for notebook in response["NotebookInstances"]:
        notebook_name = notebook["NotebookInstanceName"]
        
        # Get tags for the notebook instance
        tags = sagemaker_client.list_tags(ResourceArn=notebook["NotebookInstanceArn"])["Tags"]

        # Check if the notebook has the target tag
        for tag in tags:
            if tag["Key"] == TAG_KEY and tag["Value"] == TAG_VALUE:
                print(f"Processing notebook: {notebook_name}")

                # Stop the notebook instance if it is running
                if notebook["NotebookInstanceStatus"] in ["InService", "Pending"]:
                    print(f"Stopping notebook instance: {notebook_name}")
                    sagemaker_client.stop_notebook_instance(NotebookInstanceName=notebook_name)

                # Wait for the notebook to stop
                waiter = sagemaker_client.get_waiter("notebook_instance_stopped")
                waiter.wait(NotebookInstanceName=notebook_name)

                # Delete the notebook instance
                print(f"Deleting notebook instance: {notebook_name}")
                sagemaker_client.delete_notebook_instance(NotebookInstanceName=notebook_name)

                print(f"✅ Deleted {notebook_name}")
    
    return {
        "statusCode": 200,
        "body": "Completed processing SageMaker notebook instances."
    }
