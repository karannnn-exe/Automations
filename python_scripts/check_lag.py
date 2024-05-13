import subprocess
import re
import boto3
import logging
import os

logging.basicConfig(level=logging.INFO)

def get_consumer_offset_checker_output(zookeeper, group):
    command = ["bin/kafka-consumer-offset-checker.sh", "--zookeeper", zookeeper, "--group", group]
    try:
        result = subprocess.run(command, capture_output=True, text=True, check=True)
        return result.stdout
    except subprocess.CalledProcessError as e:
        logging.error(f"Error executing command: {e}")
        return None

def parse_offset_checker_output(output, group):
    if not output:
        logging.error("No output received from consumer offset checker.")
        return {}

    metrics = {}
    lines = output.split('\n')
    for line in lines:
        if line.strip().startswith(group):
            parts = re.split(r'\s+', line.strip())
            if len(parts) < 6:
                logging.warning(f"Unexpected output format: {line.strip()}")
                continue
            topic = parts[1]
            partition = parts[2]
            lag = int(parts[5])
            metric_name = f'{topic}_partition_{partition}_lag'
            metrics[metric_name] = lag
    return metrics

def push_metrics_to_cloudwatch(metrics):
    if not metrics:
        logging.info("No metrics to push to CloudWatch.")
        return

    try:
        session = boto3.Session()
        client = session.client('cloudwatch', region_name='us-west-2')
        for metric_name, value in metrics.items():
            response = client.put_metric_data(
                Namespace='Kafka_consumer_lag',
                MetricData=[
                    {
                        'MetricName': metric_name,
                        'Value': value,
                        'Unit': 'Count'
                    },
                ]
            )
            logging.info(f"Pushed metric: {metric_name}, Value: {value}")
    except Exception as e:
        logging.error(f"Error pushing metrics to CloudWatch: {e}")

def main():
    zookeeper = "kafka-zookeeper1.prod.rowdy.cc:2181" # zookeeper of source cluster
    group = "prod-mirrormaker-group" # consumer group
    consumer_offset_checker_output = get_consumer_offset_checker_output(zookeeper, group)
    metrics = parse_offset_checker_output(consumer_offset_checker_output, group)
    push_metrics_to_cloudwatch(metrics)

if __name__ == "__main__":
    main()
