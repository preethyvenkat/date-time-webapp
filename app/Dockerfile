FROM python:3.13.3-slim

WORKDIR /app
COPY . .
RUN pip install -r requirements.txt

EXPOSE 80
CMD ["python", "main.py"]
