#!/bin/bash

if [ -z "$1" ]; then 
    echo "usage: $0 <dev-tst-prd>"
    exit 1
fi

echo "environment: $1"

# extract summary line from plan - change path was /tmp/plan_${environment}
sed -r 's/\x1B\[[0-9;]*[mK]//g' /tmp/${1}.tfplan > /tmp/${1}_summary
summary=$(grep "Plan:" /tmp/${1}_summary || true)

# extract counts with lookahead assertions - github
add=$(echo $summary | grep -oP '(\d+)(?= to add)' || echo "0")
change=$(echo $summary | grep -oP '(\d+)(?= to change)' || echo "0")
destroy=$(echo $summary | grep -oP '(\d+)(?= to destroy)' || echo "0")

# extract resource names - adjust patterns if output format changes
add_resources=$(grep -E '^  # ' /tmp/${1}_summary | grep 'will be created' | sed 's/# //; s/ will be created//' || true)
change_resources=$(grep -E '^  # ' /tmp/${1}_summary | grep 'will be updated' | sed 's/# //; s/ will be updated.*//' || true)
destroy_resources=$(grep -E '^  # ' /tmp/${1}_summary | grep 'will be destroyed' | sed 's/# //; s/ will be destroyed//' || true)
destroy_resources=$(grep -E '^  # ' /tmp/${1}_summary | grep 'must be replaced' | sed 's/# //; s/ must be replaced//' || true)

# format as html function 
format_list_html() {
    if [ -z "$1" ]; then 
        echo "<p>none</p>"
    else
    echo "$1" | sed 's/^/<p>/' | sed 's/$/<\/p>/' | paste -sd " " -
fi
}

add_list_html=$(format_list_html "$add_resources")
change_list_html=$(format_list_html "$change_resources")
destroy_list_html=$(format_list_html "$destroy_resources")

# build html
html_content=$(cat <<EOF
<h2>🙈 terraform plan summary :: ${1}</h2>
<h3>overview</h3>
<table border="1" cellspacing="0" cellpadding="3" >
  <thead>
    <tr>
      <th align="left">action</th>
      <th align="left">count</th>
      <th align="left" >resources</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td valign="top"><strong>add</strong></td>
      <td valign="top">${add}</td>
      <td valign="top">${add_list_html}</td>
    </tr>
    <tr>
      <td valign="top"><strong>change</strong></td>
      <td valign="top">${change}</td>
      <td valign="top">${change_list_html}</td>
    </tr>
    <tr>
      <td valign="top"><strong>destroy</strong></td>
      <td valign="top">${destroy}</td>
      <td valign="top">${destroy_list_html}</td>
    </tr>
  </tbody>
</table>

<h4>👀 review detailed output prior to approval</h4>
EOF
)

echo $html_content >> $GITHUB_STEP_SUMMARY
# write summary to step summary file
echo $html_content > terraform_summary.md
# export summary to output
echo "summary<<EOF" >> $GITHUB_OUTPUT
echo "$html_content" >> $GITHUB_OUTPUT
echo "EOF" >> $GITHUB_OUTPUT

