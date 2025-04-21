FROM python:3.12-slim

WORKDIR /app

# Create a non-root user with a fixed UID and GID
ARG WORKRAVE_USER_ID=1000
ARG WORKRAVE_GROUP_ID=1000
RUN groupadd -g $WORKRAVE_GROUP_ID workrave && \
    useradd -u $WORKRAVE_USER_ID -g workrave -ms /bin/bash workrave

# Set the owner of /app and its contents to the workrave user
RUN chown -R workrave:workrave /app

# Switch to the workrave user
USER workrave

COPY requirements.txt .
RUN pip install -U pip && \
    pip install -r requirements.txt

COPY . .

CMD ["python", "process_workrave.py"]
