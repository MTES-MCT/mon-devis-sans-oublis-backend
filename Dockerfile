FROM ruby:3.4-slim

EXPOSE 3000

RUN apt-get update && apt-get upgrade -y && \
    apt-get install --no-install-recommends -y \
        build-essential git \
        libpq-dev libyaml-dev \
        nodejs npm \
        tesseract-ocr tesseract-ocr-fra libtesseract-dev imagemagick poppler-utils ghostscript && \
        rm -rf /var/lib/apt/lists/*

# 🛠️ Fix ImageMagick Security Policy for PDFs
RUN sed -i 's#<policy domain="coder" rights="none" pattern="PDF" />#<policy domain="coder" rights="read|write" pattern="PDF" />#g' /etc/ImageMagick-6/policy.xml

# do the bundle install in another directory with the strict essential
# (Gemfile and Gemfile.lock) to allow further steps to be cached
# (namely the NPM steps)
WORKDIR /bundle
COPY Gemfile Gemfile.lock ./
RUN bundle install

# Move to the main folder
WORKDIR /app

# We can't do the WORKDIR trick here because npm modules need to be
# installed in the root folder (since they're installed locally in
# node_modules)
COPY package.json package-lock.json ./

RUN npm i

COPY . .

ENTRYPOINT ["./entrypoint.sh"]

CMD ["bin/rails", "s", "-b", "0.0.0.0"]
