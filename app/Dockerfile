FROM --platform=linux/arm64 python:3.10-slim

WORKDIR /app
COPY . .
RUN pip install -r requirements.txt

EXPOSE 80
CMD ["python", "main.py"]
