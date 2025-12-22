FROM ruby:3.4-slim

ARG BUNDLE_WITHOUT
ENV BUNDLE_WITHOUT=$BUNDLE_WITHOUT

EXPOSE 3000

COPY Aptfile /app/Aptfile

# cmake pkg-config for rugged gem required by licensed gem
RUN apt-get update && apt-get upgrade -y && \
    apt-get install --no-install-recommends -y \
        build-essential git \
        cmake pkg-config \
        libpq-dev libyaml-dev \
        nodejs npm && \
    grep -vE '^\s*#' /app/Aptfile | xargs -r apt-get install --no-install-recommends -y && \
        rm -rf /var/lib/apt/lists/*

# 🛠️ Fix ImageMagick Security Policy for PDFs
RUN sed -i 's#<policy domain="coder" rights="none" pattern="PDF" />#<policy domain="coder" rights="read|write" pattern="PDF" />#g' $(readlink -f /etc/ImageMagick-*/policy.xml)

# do the bundle install in another directory with the strict essential
# (Gemfile and Gemfile.lock) to allow further steps to be cached
# (namely the NPM steps)
WORKDIR /bundle
COPY Gemfile Gemfile.lock ./
COPY lib/rnt ./lib/rnt
RUN bundle config set without "$BUNDLE_WITHOUT" && bundle install

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
