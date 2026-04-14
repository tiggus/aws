#!/bin/bash -eo pipefail

git fetch --tags
latest_version=$(git tag --sort=-creatordate | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | head -n 1 || echo "v1.0.0")
latest_version=${latest_version:-v1.0.0}
echo "latest version: $latest_version"

# check if on feature branch on github

if [[ $GITHUB_REF == refs/heads/feature/* ]]; then

    echo "feature branch detected"

    # fetch existing rc versions
    latest_version=$(echo $latest_version | awk -F. -v OFS=. '{$NF++; print}')
    echo $latest_version
    latest_rc_version=$(git tag --sort=-creatordate | grep -E "^${latest_version}-rc\.[0-9]+$" | head -n 1)
    echo "latest rc version: $latest_rc_version"

    #if no rc version exists start with rc.1
    if [[ -z $latest_rc_version ]]; then
        new_version="${latest_version}-rc.1"
    else 
        # increment rc version vX.Y.Z-rc.1 -> vX.Y.Z-rc.2
        new_version=$(echo $latest_rc_version | sed -E 's/(.*\.rc\.)([0-9]+)/\1\2/' | awk -F'.rc.' '{print $1 "-rc." $2+1}')
    fi
    echo "new rc version: $new_version"
else 
    # increment the patch version for default braanch v -> v+1
    new_version=$(echo $latest_version | awk -F. -v OFS=. '{$NF++; print}')
    echo "new version: $new_version"
fi

echo "new version: $new_version"
echo "version=$new_version" >> $GITHUB_OUTPUT

icon=$([[ ${GITHUB_REF} == refs/heads/feature/* ]] && echo "🤡" || echo "👽" )
echo "## 🚥 version" >> $GITHUB_STEP_SUMMARY
echo "" >> $GITHUB_STEP_SUMMARY
echo "| key | value |" >> $GITHUB_STEP_SUMMARY
echo "| :--------- | :--------- |" >> $GITHUB_STEP_SUMMARY
echo "| latest | ${latest_version} |" >> $GITHUB_STEP_SUMMARY
echo "| new | ${new_version} |" >> $GITHUB_STEP_SUMMARY
echo "| status | $icon ${new_version} |" >> $GITHUB_STEP_SUMMARY
