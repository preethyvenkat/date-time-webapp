from flask import Flask
from datetime import datetime

app = Flask(__name__)

@app.route("/")
def index():
    now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    return f"<h1>Current Date and Time</h1><p>{now}</p><script>setTimeout(()=>location.reload(), 3000)</script>"

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=80)
