# Dataset Uploader Lambda service


## Example Event
This shows how an event should be formatted for this lambda to work:
```
{
    bucket: <your-s3-bucket-id>
    dataset_folder: "/path/to/your/dataset"     # <- This folder will be copied into EFS at /mnt/datasets/{dataset_folder}/*
}
```