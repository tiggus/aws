```sh
region='eu-west-2'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RESET='\033[0m'
BOLD='\033[1m'

get_clusters() {
    declare -a clusters\
    clusters=($(aws eks list-clusters --region $1 | jq -r '.clusters[]'))
    echo $clusters
}

write_output() {
    echo $BOLD"$1: "$GREEN$2$RESET | tr '[:upper:]' '[:lower:]'
}

get_cluster_info() {
    local counter=0
    declare -a clusters
    clusters=($(get_clusters $1))
    for cluster in "${clusters[@]}"; do
        write_output "cluster[$counter]" $cluster
        counter=$((counter+1))
        k8s_version=$(aws eks describe-cluster --name "$cluster" --region "$1" --output json 2>/dev/null | jq -r '.cluster.version')
        write_output  "k8s" $k8s_version
        declare -a addons
        addons=($(aws eks list-addons --cluster-name "$cluster" --region "$1" --output json 2>/dev/null | jq -r '.addons[]'))
        for addon in $addons; do
            addon_info=$(aws eks describe-addon --cluster-name "$cluster" --addon-name "$addon" --region "$1" --output json 2>/dev/null | jq -r '. | "\(.addon.addonVersion):\(.addon.status)"')
            write_output "$addon" "$(echo $addon_info | cut -d ":" -f 1) $(echo $addon_info | cut -d ":" -f 2)"
            latest_version=$(aws eks describe-addon-versions --addon-name "$addon" --kubernetes-version "$k8s_version" --region "$1" --output json 2>/dev/null | jq -r '.addons[0].addonVersions | map(select(.compatibilities[]?.defaultVersion == true)) | if length > 0 then .[0].addonVersion else null end')
            cmp_result=0
            compare $(echo $addon_info | cut -d ":" -f 1) "$latest_version" || cmp_result=$?
            if [[ "$cmp_result" -eq 1 ]]; then
               status_str="${YELLOW}update${RESET} $latest_version"
            else
                status_str="${GREEN}latest${RESET}"
           fi
            echo $status_str\\n
        done
        echo ""
    done
}

compare() {
if [ "$1" = "$2" ]; then
    return 0
else
    return 1
fi
}

get_cluster_info $region
``
