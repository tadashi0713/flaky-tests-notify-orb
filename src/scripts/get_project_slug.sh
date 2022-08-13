#!/bin/bash -eu

# echo "export PROJECT_SLUG=$(echo "$CIRCLE_BUILD_URL" | sed -e "s|https://circleci.com/||g" -e "s|/[0-9]*$||g")" >> "$BASH_ENV"

echo "export PROJECT_SLUG='gh/tadashi0713/circleci-demo-test-insights'" >> "$BASH_ENV"
