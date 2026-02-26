function output() {
  printf '%s\n' "${1}"
}


function warn() {
  output "Warning:  ${1}" >&2
}


function fail() {
  output "Error:  ${1}" >&2
  exit "${2:-1}"
}


function debug() {
  output "DEBUG:  ${1}" >&2
}
