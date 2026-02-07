pipeline {
    agent { label 'mac' }

    environment {
        XCWORKSPACE  = 'Playground.xcworkspace'
        SCHEME       = 'Playground'
        SDK          = 'iphonesimulator'
        DEVICE_TYPE  = 'com.apple.CoreSimulator.SimDeviceType.iPhone-16'
        RUNTIME      = 'com.apple.CoreSimulator.SimRuntime.iOS-18-4'
        DERIVED_DATA = "${WORKSPACE}/DerivedData"
        RESULTS_DIR  = "${WORKSPACE}/TestResults"
        SIM_PREFIX   = 'ParallelTestRunner'
        SIM_COUNT    = '3'
        XCBEAUTIFY   = '/opt/homebrew/bin/xcbeautify'
        RECIPIENT    = 'jaden@designergen.es'
    }

    options {
        timeout(time: 30, unit: 'MINUTES')
        timestamps()
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Install Dependencies') {
            steps {
                sh '''
                    export PATH="/opt/homebrew/bin:$PATH"
                    tuist install
                    tuist generate --no-open
                    pod install --repo-update
                '''
            }
        }

        stage('Build for Testing') {
            steps {
                sh """
                    set -o pipefail
                    export PATH="/opt/homebrew/bin:\$PATH"
                    xcodebuild build-for-testing \\
                        -workspace \${XCWORKSPACE} \\
                        -scheme \${SCHEME} \\
                        -sdk \${SDK} \\
                        -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' \\
                        -derivedDataPath \${DERIVED_DATA} \\
                        ONLY_ACTIVE_ARCH=NO \\
                        2>&1 | \${XCBEAUTIFY}
                """
            }
        }

        stage('Create & Configure Simulators') {
            steps {
                script {
                    def udids = []
                    def simCount = env.SIM_COUNT.toInteger()

                    for (int i = 1; i <= simCount; i++) {
                        def simName = "${env.SIM_PREFIX}-${i}"

                        // Clean up any stale simulator with the same name
                        sh(script: "xcrun simctl delete '${simName}' 2>/dev/null || true",
                           returnStatus: true)

                        // Create the simulator
                        def udid = sh(
                            script: "xcrun simctl create '${simName}' '${env.DEVICE_TYPE}' '${env.RUNTIME}'",
                            returnStdout: true
                        ).trim()

                        echo "Created simulator '${simName}' with UDID: ${udid}"
                        udids.add(udid)

                        // --- Plist injection BEFORE booting ---
                        def homeDir = sh(script: 'echo $HOME', returnStdout: true).trim()
                        def prefsDir = "${homeDir}/Library/Developer/CoreSimulator/Devices/${udid}/data/Library/Preferences"

                        sh "mkdir -p '${prefsDir}'"

                        // Disable slide-to-type (Continuous Path keyboard)
                        sh """
                            /usr/libexec/PlistBuddy -c "Add :KeyboardContinuousPathEnabled bool false" \\
                                '${prefsDir}/com.apple.keyboard.ContinuousPath.plist' \\
                                2>/dev/null || \\
                            /usr/libexec/PlistBuddy -c "Set :KeyboardContinuousPathEnabled false" \\
                                '${prefsDir}/com.apple.keyboard.ContinuousPath.plist'
                        """

                        // Disable autocorrection and predictive text
                        sh """
                            /usr/libexec/PlistBuddy -c "Add :KeyboardAutocorrection bool false" \\
                                '${prefsDir}/com.apple.Preferences.plist' 2>/dev/null || true
                            /usr/libexec/PlistBuddy -c "Add :KeyboardPrediction bool false" \\
                                '${prefsDir}/com.apple.Preferences.plist' 2>/dev/null || true
                        """

                        // Boot the simulator
                        sh "xcrun simctl boot '${udid}'"

                        // Wait for boot to complete
                        sh "xcrun simctl bootstatus '${udid}' -b"

                        echo "Simulator '${simName}' (${udid}) booted with slide-to-type disabled."
                    }

                    env.SIM_UDIDS = udids.join(',')
                    echo "All simulator UDIDs: ${env.SIM_UDIDS}"
                }
            }
        }

        stage('Discover & Shard Tests') {
            steps {
                script {
                    // Parse Swift source files to discover test class/method pairs
                    def testList = sh(
                        script: '''
                            for f in PlaygroundUITests/Sources/*.swift; do
                                CLASS=$(grep -o 'class [A-Za-z]*' "$f" | head -1 | awk '{print $2}')
                                grep 'func test' "$f" | sed 's/.*func \\(test[^(]*\\).*/\\1/' | while read -r METHOD; do
                                    echo "PlaygroundUITests/${CLASS}/${METHOD}"
                                done
                            done
                        ''',
                        returnStdout: true
                    ).trim().split('\n').toList()

                    echo "Discovered ${testList.size()} tests:"
                    testList.each { echo "  - ${it}" }

                    // Shard tests across simulators via round-robin
                    def simCount = env.SIM_COUNT.toInteger()
                    def shards = (0..<simCount).collect { [] }

                    testList.eachWithIndex { test, idx ->
                        shards[idx % simCount].add(test)
                    }

                    for (int i = 0; i < simCount; i++) {
                        env."TEST_SHARD_${i}" = shards[i].join(',')
                        echo "Shard ${i} (${shards[i].size()} tests): ${shards[i]}"
                    }
                }
            }
        }

        stage('Run Tests in Parallel') {
            steps {
                script {
                    def udids = env.SIM_UDIDS.split(',')
                    def simCount = env.SIM_COUNT.toInteger()

                    // Locate the xctestrun file
                    def xctestrunFile = sh(
                        script: "find ${env.DERIVED_DATA}/Build/Products -name '*.xctestrun' -type f | head -1",
                        returnStdout: true
                    ).trim()

                    echo "Using xctestrun: ${xctestrunFile}"

                    sh "mkdir -p ${env.RESULTS_DIR}"

                    def branches = [:]

                    for (int i = 0; i < simCount; i++) {
                        def shardIndex = i
                        def udid = udids[shardIndex]
                        def shardTests = env."TEST_SHARD_${shardIndex}".split(',')
                        def onlyTestingFlags = shardTests.collect { "-only-testing:${it}" }.join(' ')
                        def resultBundle = "${env.RESULTS_DIR}/shard-${shardIndex}.xcresult"
                        def junitDir = "${env.RESULTS_DIR}/shard-${shardIndex}"
                        def capturedXctestrun = xctestrunFile

                        branches["Shard ${shardIndex}"] = {
                            sh """
                                set -o pipefail
                                export PATH="/opt/homebrew/bin:\$PATH"
                                mkdir -p '${junitDir}'
                                xcodebuild test-without-building \\
                                    -xctestrun '${capturedXctestrun}' \\
                                    -destination 'platform=iOS Simulator,id=${udid}' \\
                                    -resultBundlePath '${resultBundle}' \\
                                    -parallel-testing-enabled NO \\
                                    ${onlyTestingFlags} \\
                                    2>&1 | \${XCBEAUTIFY} \\
                                        --report junit \\
                                        --report-path '${junitDir}' \\
                                        --junit-report-filename 'junit.xml'
                            """
                        }
                    }

                    parallel branches
                }
            }
        }

        stage('Merge Results') {
            steps {
                sh """
                    python3 - '${env.RESULTS_DIR}' << 'PYEOF'
import xml.etree.ElementTree as ET
import sys
import glob
import os

results_dir = sys.argv[1]
files = sorted(glob.glob(os.path.join(results_dir, 'shard-*/junit.xml')))

root = ET.Element('testsuites')
total_tests = 0
total_failures = 0
total_errors = 0
total_time = 0.0

for f in files:
    tree = ET.parse(f)
    for elem in tree.getroot().iter():
        if elem.tag == 'testsuite':
            root.append(elem)
            total_tests += int(elem.get('tests', 0))
            total_failures += int(elem.get('failures', 0))
            total_errors += int(elem.get('errors', 0))
            total_time += float(elem.get('time', 0))

root.set('tests', str(total_tests))
root.set('failures', str(total_failures))
root.set('errors', str(total_errors))
root.set('time', str(round(total_time, 3)))

output = os.path.join(results_dir, 'junit-merged.xml')
tree = ET.ElementTree(root)
tree.write(output, encoding='unicode', xml_declaration=True)
print(f'Merged {len(files)} JUnit files -> {output}')
print(f'Total: {total_tests} tests, {total_failures} failures, {total_errors} errors, {round(total_time, 3)}s')
PYEOF
                """
            }
        }

        stage('Publish Results') {
            steps {
                junit testResults: 'TestResults/junit-merged.xml',
                     allowEmptyResults: false

                archiveArtifacts artifacts: 'TestResults/**',
                                 allowEmptyArchive: true
            }
        }
    }

    post {
        always {
            script {
                // Shut down and delete all test simulators
                if (env.SIM_UDIDS) {
                    def udids = env.SIM_UDIDS.split(',')
                    for (udid in udids) {
                        sh(script: "xcrun simctl shutdown '${udid}' 2>/dev/null || true",
                           returnStatus: true)
                        sh(script: "xcrun simctl delete '${udid}' 2>/dev/null || true",
                           returnStatus: true)
                    }
                    echo 'All test simulators cleaned up.'
                }
            }
        }
        success {
            emailext(
                to: env.RECIPIENT,
                subject: "SUCCESS: ParallelTestDemo #${BUILD_NUMBER}",
                body: """<h2>Build Succeeded</h2>
<p><strong>Job:</strong> ${JOB_NAME} #${BUILD_NUMBER}</p>
<p><strong>Duration:</strong> ${currentBuild.durationString}</p>
<h3>Test Results</h3>
<p>All UI tests passed across 3 parallel simulators.</p>
<p><a href="${BUILD_URL}testReport/">View Full Test Report</a></p>
<p><a href="${BUILD_URL}">View Build</a></p>""",
                mimeType: 'text/html',
                attachmentsPattern: 'TestResults/junit-merged.xml'
            )
        }
        failure {
            emailext(
                to: env.RECIPIENT,
                subject: "FAILURE: ParallelTestDemo #${BUILD_NUMBER}",
                body: """<h2>Build Failed</h2>
<p><strong>Job:</strong> ${JOB_NAME} #${BUILD_NUMBER}</p>
<p><strong>Duration:</strong> ${currentBuild.durationString}</p>
<p><a href="${BUILD_URL}console">Console Output</a></p>
<p><a href="${BUILD_URL}testReport/">Test Report</a></p>""",
                mimeType: 'text/html',
                attachmentsPattern: 'TestResults/junit-merged.xml'
            )
        }
    }
}
