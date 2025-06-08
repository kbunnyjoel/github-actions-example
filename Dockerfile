# Use an official Node.js runtime as a parent image
# Using a specific LTS version like 20-alpine is good for smaller images and stability
FROM node:20.19.2-alpine3.22

# Set the working directory in the container
WORKDIR /usr/src/app

# Copy package.json and package-lock.json (if available)
# This step is separate to leverage Docker's layer caching.
# If package.json or package-lock.json haven't changed, Docker can reuse this layer.
COPY package*.json ./

# Install project dependencies
# Use npm ci for cleaner, faster, and more reliable installs in CI/Docker
RUN npm ci
RUN rm -r /usr/local/lib/node_modules/npm/node_modules/cross-spawn/
RUN rm -r /usr/lib/node_modules_20/npm/node_modules/cross-spawn/
RUN rm -r /usr/local/n/versions/node/18.20.5/lib/node_modules/npm/node_modules/cross-spawn/

# Copy the rest of your application's code into the container
COPY . .

EXPOSE 3000

# Command to run your tests when the container starts
CMD [ "npm", "start" ]
