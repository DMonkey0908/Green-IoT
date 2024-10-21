import firebase_admin
from firebase_admin import credentials
from firebase_admin import db
import time
import random

cred = credentials.Certificate('esp32-random-firebase-adminsdk-ykyz6-135398669f.json')
firebase_admin.initialize_app(cred, {
    'databaseURL': 'https://esp32-random-default-rtdb.asia-southeast1.firebasedatabase.app/'
})

user = "msofficialdn64@gmailcom"
path = "/HOME"

ref = db.reference(path)

ref.update({
    user : ""
})

print("Added " + user +" to /HOME")