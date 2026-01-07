# Use the standard Node image (not Alpine) to avoid missing tools
FROM node:18 as build

WORKDIR /app
COPY package*.json ./

# ADDED THE FLAG HERE:
RUN npm install --legacy-peer-deps

COPY . .
RUN npm run build

# Stage 2: Serve with Nginx
FROM nginx:alpine
COPY --from=build /app/dist /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]