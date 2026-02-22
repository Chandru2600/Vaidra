FROM python:3.11-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

ENV PYTHONUNBUFFERED=1

# Fix Windows CRLF line endings in start.sh
RUN sed -i 's/\r//' start.sh && chmod +x start.sh

CMD ["./start.sh"]
