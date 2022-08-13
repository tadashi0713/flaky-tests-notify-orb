#!/bin/bash

# Fetch flaky tests API(https://circleci.com/docs/api/v2/index.html#operation/getFlakyTests)
res=$(curl --request GET \
--url "https://circleci.com/api/v2/insights/${PROJECT_SLUG}/flaky-tests" \
--header "circle-token: $CIRCLE_TOKEN")

# Skip if flaky tests don't exist
flaky_tests_count=$(echo $res | jq '.total_flaky_tests')
if [ $flaky_tests_count = '0' ]; then
  echo "Flaky tests not found!"
  circleci-agent step halt
fi

# Create Slack template
template=$(cat \<< EOS
{
  "blocks": [
    {
      "type": "section",
      "text": {
        "type": "mrkdwn",
        "text": ":warning: Flaky tests detected to *${CIRCLE_PROJECT_REPONAME}* project."
      }
    }
  ]
}
EOS
)

# Get each flaky tests & append to the template
for i in $( seq 0 $(($flaky_tests_count - 1)) ); do
  flaky_test=`echo ${res} | jq .flaky_tests[${i}]`
  test_name=`echo ${flaky_test} | jq -r .test_name`
  classname=`echo ${flaky_test} | jq -r .classname`
  source=`echo ${flaky_test} | jq -r .source`
  times_flaked=`echo ${flaky_test} | jq -r .times_flaked`
  job_name=`echo ${flaky_test} | jq -r .job_name`
  job_number=`echo ${flaky_test} | jq -r .job_number`
  workflow_id=`echo ${flaky_test} | jq -r .workflow_id`
  workflow_created_at=`echo ${flaky_test} | jq -r .workflow_created_at`
  pipeline_number=`echo ${flaky_test} | jq -r .pipeline_number`
  
  # Create last flaked message using datediff
  if [ `datediff ${workflow_created_at} today -f "%Y"` != '0' ]; then
    last_flaked_message=$(datediff ${workflow_created_at} today -f "%Y years ago")
  elif [ `datediff ${workflow_created_at} today -f "%m"` != '0' ]; then
    last_flaked_message=$(datediff ${workflow_created_at} today -f "%m months ago")
  elif [ `datediff ${workflow_created_at} today -f "%d"` != '0' ]; then
    last_flaked_message=$(datediff ${workflow_created_at} today -f "%d days ago")
  elif [ `datediff ${workflow_created_at} today -f "%H"` != '0' ]; then
    last_flaked_message=$(datediff ${workflow_created_at} today -f "%H hours ago")
  elif [ `datediff ${workflow_created_at} today -f "%M"` != '0' ]; then
    last_flaked_message=$(datediff ${workflow_created_at} today -f "%M minutes ago")
  else
    last_flaked_message=$(datediff ${workflow_created_at} today -f "%S seconds ago")
  fi
  
  flaky_test_template=$(cat \<< EOS
  {
    "type": "divider"
  },
  {
    "type": "section",
    "text": {
      "type": "mrkdwn",
      "text": "*${test_name}*"
      }
    },
  {
    type: "section",
    fields: [
      {
        type: "mrkdwn",
        text: "*Classname:* ${classname}"
      },
      {
        type: "mrkdwn",
        text: "*Source:* ${source}"
      },
      {
        type: "mrkdwn",
        text: "*Job:* ${job_name}"
      },
      {
        type: "mrkdwn",
        text: "*Times flaked:* ${times_flaked}"
      },
      {
        type: "mrkdwn",
        text: "*Last flaked:* <https://app.circleci.com/pipelines/${PROJECT_SLUG}/${pipeline_number}/workflows/${workflow_id}/jobs/${job_number}/tests|${last_flaked_message}>"
      }
    ]
  }
EOS
)
  template=$(echo $template | jq ".blocks |= . + [$flaky_test_template]")
done

# Append end template
end_template=$(cat \<< EOS
{
  "type": "divider"
},
{
  "type": "actions",
  "elements": [
    {
      "type": "button",
      "text": {
        "type": "plain_text",
        "text": "Go to Insights dashboard",
      },
      "url": "https://app.circleci.com/insights/${PROJECT_SLUG}"
    }
  ]
}
EOS
)

template=$(echo $template | jq ".blocks |= . + [$end_template]")

# Add to environment vatiables
echo $template | jq > /tmp/SlackTemplateForFlakyTests.json
echo 'export SLACK_TEMPLATE_FOR_FLAKY_TESTS=$(cat /tmp/SlackTemplateForFlakyTests.json)' >> $BASH_ENV
