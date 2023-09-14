
def injectEnvironments(Closure body) {
    withEnv([
        "PATH=/var/lib/jenkins/.rbenv/shims:/var/lib/jenkins/.rbenv/bin:/Applications/MEGAcmd.app/Contents/MacOS:/Applications/CMake.app/Contents/bin:$PATH:/usr/local/bin",
        "LC_ALL=en_US.UTF-8",
        "LANG=en_US.UTF-8"
    ]) {
        body.call()
    }
}

pipeline {
    agent { label 'macstudio1' }
    options {
        timeout(time: 1, unit: 'HOURS') 
        gitLabConnection('GitLabConnection')
        gitlabCommitStatus(name: 'Jenkins')
    }
    post { 
        failure {
            script {
                if (env.BRANCH_NAME.startsWith('MR-')) {
                    def mrNumber = env.BRANCH_NAME.replace('MR-', '')

                    withCredentials([usernameColonPassword(credentialsId: 'Jenkins-Login', variable: 'CREDENTIALS')]) {
                        sh 'curl -u $CREDENTIALS ${BUILD_URL}/consoleText -o console.txt'
                    }

                    withCredentials([usernamePassword(credentialsId: 'Gitlab-Access-Token', usernameVariable: 'USERNAME', passwordVariable: 'TOKEN')]) {
                        final String logsResponse = sh(script: 'curl -s --request POST --header PRIVATE-TOKEN:$TOKEN --form file=@console.txt https://code.developers.mega.co.nz/api/v4/projects/193/uploads', returnStdout: true).trim()
                        def logsJSON = new groovy.json.JsonSlurperClassic().parseText(logsResponse)
                        env.MARKDOWN_LINK = ":x: Build status check Failed <br />Build Log: ${logsJSON.markdown}"
                        env.MERGE_REQUEST_URL = "https://code.developers.mega.co.nz/api/v4/projects/193/merge_requests/${mrNumber}/notes"
                        sh 'curl --request POST --header PRIVATE-TOKEN:$TOKEN --form body=\"${MARKDOWN_LINK}\" ${MERGE_REQUEST_URL}'
                    }
                } else {
                    withCredentials([usernameColonPassword(credentialsId: 'Jenkins-Login', variable: 'CREDENTIALS')]) {
                        def comment = ":x: Build failed for branch: ${env.GIT_BRANCH}"
                        if (env.CHANGE_URL) {
                            comment = ":x: Build failed for branch: ${env.GIT_BRANCH} \nMR Link:${env.CHANGE_URL}"
                        }
                        slackSend color: "danger", message: comment
                        sh 'curl -u $CREDENTIALS ${BUILD_URL}/consoleText -o console.txt'
                        slackUploadFile filePath:"console.txt", initialComment:"iOS Build Log"
                    }
                }
            }
            
            updateGitlabCommitStatus name: 'Jenkins', state: 'failed'
        }
        success {
            script {
                injectEnvironments({
                    if (env.BRANCH_NAME.startsWith('MR-')) {
                        def mr_number = env.BRANCH_NAME.replace('MR-', '')

                        withCredentials([usernamePassword(credentialsId: 'Gitlab-Access-Token', usernameVariable: 'USERNAME', passwordVariable: 'TOKEN')]) {
                            sh 'bundle exec fastlane parse_and_upload_code_coverage mr:' + mr_number + ' token:' + TOKEN
                            env.MARKDOWN_LINK = ":white_check_mark: Build status check succeeded"
                            env.MERGE_REQUEST_URL = "https://code.developers.mega.co.nz/api/v4/projects/193/merge_requests/${mr_number}/notes"
                            sh 'curl --request POST --header PRIVATE-TOKEN:$TOKEN --form body=\"${MARKDOWN_LINK}\" ${MERGE_REQUEST_URL}'
                        }
                    }
                })
            }

            updateGitlabCommitStatus name: 'Jenkins', state: 'success'
        }
        always {
            script {
                withCredentials([usernamePassword(credentialsId: 'Gitlab-Access-Token', usernameVariable: 'USERNAME', passwordVariable: 'TOKEN')]) {
                    injectEnvironments({
                        if (env.BRANCH_NAME.startsWith('MR-')) {
                            def mr_number = env.BRANCH_NAME.replace('MR-', '')
                            sh 'bundle exec fastlane parse_and_upload_build_warnings_and_errors mr:' + mr_number + ' token:' + TOKEN
                        }
                    })
                }
            }
        }
        cleanup {
            cleanWs()
        }
    }
    stages {
        stage('Bundle install') {
            steps {
                gitlabCommitStatus(name: 'Bundle install') {
                    injectEnvironments({
                        sh "bundle install"
                    })
                }
            }
        }

        stage('Installing dependencies') {
            parallel {
                stage('Submodule update and run cmake') {
                    steps {
                        gitlabCommitStatus(name: 'Submodule update and run cmake') {
                            withCredentials([gitUsernamePassword(credentialsId: 'Gitlab-Access-Token', gitToolName: 'Default')]) {
                                injectEnvironments({
                                    sh "git submodule foreach --recursive git clean -xfd"
                                    sh "git submodule sync --recursive"
                                    sh "git submodule update --init --recursive"
                                    dir("Modules/DataSource/MEGAChatSDK/Sources/MEGAChatSDK/src/") {
                                        sh "cmake -P genDbSchema.cmake"
                                    }
                                })
                            }
                        }
                    }
                }

                stage('Downloading third party libraries') {
                    steps {
                        gitlabCommitStatus(name: 'Downloading third party libraries') {
                            injectEnvironments({
                                sh "bundle exec fastlane configure_sdk_and_chat_library use_cache:true"
                            })
                        }
                    }
                }

                stage('Boot Simulators') {
                    steps {
                        gitlabCommitStatus(name: 'Bundle install') {
                            injectEnvironments({
                                sh "./scripts/boot-simulators.sh"
                            })
                        }
                    }
                }
            }
        }

        stage('main app - Run Unit test and generate code coverage') {
            steps {
                gitlabCommitStatus(name: 'main app - Run unit tes and generate code coveraget') {
                    withCredentials([gitUsernamePassword(credentialsId: 'Gitlab-Access-Token', gitToolName: 'Default')]) {
                        injectEnvironments({
                            sh "bundle exec fastlane run_tests_app"
                        })
                    }
                }
            }
        }
    }
}