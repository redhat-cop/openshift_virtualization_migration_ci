#!/bin/bash

export SARIF_REPORT_FULL_PATH="./code-quality-report.sarif"
export LINT_ARGS="--profile production"

if [[ "["tests/integration/", "tests/unit"]" != "" ]]; then
    FLAG=" --exclude"
    EXCLUDE_ARGS=$(echo '["tests/integration/", "tests/unit"]' | tr -d '[],"')
    set -- $EXCLUDE_ARGS
    for item in "$@"; do
        LINT_ARGS+=" $FLAG $item"
    done
fi

if true ; then LINT_ARGS+=" --parseable"; fi
if true ; then LINT_ARGS+=" --force-color"; fi
if false ; then LINT_ARGS+=" --offline"; fi
if true ; then LINT_ARGS+=" --strict"; fi
if true ; then LINT_ARGS+=" --sarif-file ${SARIF_REPORT_FULL_PATH}"; fi

ansible-lint --version

echo "Running ansible-lint with the following parameters"
echo "${LINT_ARGS}"

echo "Switch directories to project directory ."
cd .

ansible-lint ${LINT_ARGS} || RETURN=$?
if true && ! [ -f ${SARIF_REPORT_FULL_PATH} ] ; then
    echo "Code quality sarif report was requested but not generated, please check the logs."
    RETURN=1${RETURN}
fi
if [[ 0 == $RETURN ]]; then
    echo "Return code $RETURN matches expected return"
    exit 0
fi
echo $RETURN