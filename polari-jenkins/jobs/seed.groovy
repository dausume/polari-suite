// Job DSL seed (loaded by Configuration as Code on every boot — jobs are
// code, never clicked together). Three pipelines; every one POLLS.
def repo = 'https://github.com/dausume/polari-suite.git'
def pipe = { name -> new File("/var/polari-jenkins/pipelines/${name}").text }  // JCasC runs the DSL without a workspace

pipelineJob('polari-dev-build') {
    description('Poll dev every 10 min; recursive checkout; build debs (both flavors) + images. Publishes nothing.')
    logRotator { numToKeep(20) }
    triggers { scm('H/10 * * * *') }
    definition { cps { script(pipe('Jenkinsfile.dev-build')); sandbox(true) } }
}
pipelineJob('polari-release') {
    description('Poll main every 10 min; build everything + release.json + offline medium into pool/<version>/; triggers polari-publish with DRY_RUN=true.')
    logRotator { numToKeep(30) }
    triggers { scm('H/10 * * * *') }
    parameters { booleanParam('BUILD_OFFLINE_MEDIUM', true, 'assemble offline-build/<version>/ (2 GB, minutes)') }
    definition { cps { script(pipe('Jenkinsfile.release')); sandbox(true) } }
}
pipelineJob('polari-publish') {
    description('ci-6: publish pool/<VERSION>/ to the selected routes. DRY_RUN=true renders every command and pushes nothing.')
    logRotator { numToKeep(50) }
    parameters {
        stringParam('VERSION', '', 'polari version under pool/ (e.g. 2026.09.07-dev+7d6db81)')
        booleanParam('DRY_RUN', true, 'render only — the default; set false to push')
        stringParam('ROUTES', 'github-release,apt-repo,ghcr', 'comma list of ACTIVE routes: github-release,apt-repo,ghcr,homebrew (parked: routes/later/)')
    }
    definition { cps { script(pipe('Jenkinsfile.publish')); sandbox(true) } }
}
