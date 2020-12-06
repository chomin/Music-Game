# carthage.sh
# Usage example: ./carthage.sh update --platform iOS

set -eu

# GNU版ののreadlinkにのみ対応しているので必要に応じて以下のコメントを外す
# alias readlink='greadlink'
export XCODE_XCCONFIG_FILE="$(readlink -f $(dirname $0))/Carthage/carthage_workaround_for_xcode12.xcconfig"
echo $XCODE_XCCONFIG_FILE
carthage "$@"
