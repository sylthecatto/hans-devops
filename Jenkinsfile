pipeline {
    agent any

    environment {
        APP_NAME    = 'portal-c'
        // pulled from Jenkins credentials
        REGISTRY    = credentials('docker-registry-url')
        CONFIG_REPO = 'github.com/sylthecatto/hans-devops-config.git'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
                script {
                    env.GIT_SHORT = sh(
                        script: 'git rev-parse --short HEAD',
                        returnStdout: true
                    ).trim()
                }
            }
        }

        stage('Determine Version & Target Branch') {
            steps {
                script {
                    if (env.TAG_NAME) {
                        // PRODUCTION -- only runs when I explicitly push a tag
                        if (!(env.TAG_NAME ==~ /^v[0-9]+\.[0-9]+\.[0-9]+$/)) {
                            error("Tag '${env.TAG_NAME}' is not vX.Y.Z")
                        }
                        env.VERSION       = env.TAG_NAME
                        env.CONFIG_BRANCH = 'production'
                    } else if (env.BRANCH_NAME == 'staging') {
                        // STAGING -- every push to staging. Never 'latest'.
                        env.VERSION       = "staging-${env.GIT_SHORT}"
                        env.CONFIG_BRANCH = 'staging'
                    } else {
                        // any other branch push (e.g. production) does nothing
                        env.VERSION       = ''
                        env.CONFIG_BRANCH = ''
                        echo "Branch ${env.BRANCH_NAME} does not deploy"
                    }
                    env.IMAGE = "${env.REGISTRY}/${env.APP_NAME}:${env.VERSION}"
                    echo "Version=${env.VERSION}  ConfigBranch=${env.CONFIG_BRANCH}"
                }
            }
        }

        stage('Build & Push Image') {
            when { expression { env.CONFIG_BRANCH != '' } }
            steps {
                sh '''
                    docker build --build-arg APP_VERSION=${VERSION} -t ${IMAGE} .
                    docker push ${IMAGE}
                '''
            }
        }

        stage('Update Config Repo') {
            when { expression { env.CONFIG_BRANCH != '' } }
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'github-devops-ci',
                    usernameVariable: 'GIT_USER',
                    passwordVariable: 'GIT_PASS'
                )]) {
                    sh '''
                        rm -rf config-repo
                        git clone -b ${CONFIG_BRANCH} \
                            https://${GIT_USER}:${GIT_PASS}@${CONFIG_REPO} config-repo
                        cd config-repo

                        sed -i "s|image: .*/${APP_NAME}:.*|image: ${IMAGE}|g" deployment.yaml

                        git config user.email "sylthecatto@github.com"
                        git config user.name  "sylthecatto"
                        git add deployment.yaml
                        git commit -m "ci: ${CONFIG_BRANCH} image -> ${VERSION}" || echo "no change"
                        git push origin ${CONFIG_BRANCH}
                    '''
                }
            }
        }
    }

    post {
        success { echo "Done: ${env.VERSION} -> ${env.CONFIG_BRANCH}" }
        failure { echo "Build failed -- nothing deployed." }
    }
}

