FROM debian:stretch
RUN \
  # Update package lists.
  DEBIAN_FRONTEND=noninteractive apt-get -y update && \

  # Install various packages.
  DEBIAN_FRONTEND=noninteractive apt-get -y install \
    # Make
    build-essential \

    # Coq
    coq \

    # For installing the AWS CLI below
    python-pip \

    # LaTeX
    texlive-full && \

  # Now that the packages are installed, free up some space by removing the
  # package lists.
  rm -rf /var/lib/apt/lists/* && \

  # Install the AWS CLI.
  pip install awscli && \

  # Free up 2G of disk space.
  rm -rf /usr/share/doc