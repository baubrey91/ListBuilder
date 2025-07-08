#  OptiNote
OptiNote is a utility application that allows you to take scan all of the words in a photo and send it up to a google doc. In addition to the application there is a share extension.

## Use Case
Problem - I would take photos of things a reminders or todos (usually I would see places I wanted to go on instrgram and screenshot it). This made it hard for me to refind these photos in my entire library.
Solution - This application allows me to screenshot the text (usually name or location or address) and send it to a google doc of my reminders.

## Instructions
- Login in via Google Sign in
- Select a file in google you would like to send your note to
- Import an image
- Draw around the section of the image you want to extract text from
- Edit text (optional)
- Send to google

- ## Instructions (Extentions)
- Select image from photos
- Extracts text from image immediately
- Edit text (optional)
- Select file to send to and send

## Features
- Log in/out via google sign in
- Search all google docs/folders
- Send extracted data to google docs
- Persisted recently used files for share extension
- Error handling


## Processing
The image processing is done in three steps 
1. Crop the image to have a 160 x 144 ratio
2. Reduce the image to a planar2 grayscale ie each pixel holds 2 bits which is 4 colors. Here we also need to dither which is build into the Accelerate Framework
3. Iterate through each pixel and map the gray value to a green value


## Sample 
| Import to google |
|------|
|https://github.com/user-attachments/assets/f91342ca-a9a3-408e-b719-d9fd3092bd46|

# TODO add more
