FROM nginx

COPY ["run", "/run/"]
WORKDIR /run

# override CMD instruction from nginx image
CMD ["./run.sh"]