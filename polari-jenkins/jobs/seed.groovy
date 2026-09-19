// Job DSL seed (loaded by Configuration as Code on every boot — jobs are
// code, never clicked together). Three pipelines; every one POLLS.
def repo = 'https://github.com/dausume/polari-suite.git'
def pipe = { name -> new File("/var/polari-jenkins/pipelines/${name}").text }  // JCasC runs the DSL without a workspace

pipelineJob('polari-dev-build') {
    description('Poll dev every 10 min; recursive checkout; build debs (both flavors) + images. Publishes nothing.')
    logRotator { numToKeep(5); artifactNumToKeep(2) }   // dev artifacts: two builds' debs, no more
    triggers { scm('H/10 * * * *') }
    definition { cps { script(pipe('Jenkinsfile.dev-build')); sandbox(true) } }
}
pipelineJob('polari-release') {
    description('Poll main every 10 min; build everything + release.json + offline medium into pool/<version>/; triggers polari-publish with DRY_RUN=true.')
    logRotator { numToKeep(10); artifactNumToKeep(3) }  // the pool itself is pruned by retention.sh (POOL_KEEP)
    triggers { scm('H/10 * * * *') }
    parameters { booleanParam('BUILD_OFFLINE_MEDIUM', true, 'assemble offline-build/<version>/ (2 GB, minutes)') }
    definition { cps { script(pipe('Jenkinsfile.release')); sandbox(true) } }
}
pipelineJob('polari-publish') {
    description('ci-6: publish pool/<VERSION>/ to the selected routes. DRY_RUN=true renders every command and pushes nothing.')
    logRotator { numToKeep(50) }
    parameters {
        stringParam('VERSION', '', 'polari version under pool/ (e.g. 2026.09.07-dev+7d6db81)')
        // ci-7 (C): auto = publish for real only where the secret is present AND the route is in CI_ROUTES
        choiceParam('DRY_RUN', ['auto', 'true', 'false'], 'auto (default): armed per route by secret + CI_ROUTES · true: render only · false: force a real push')
        stringParam('ROUTES', 'github-release,ghcr,homebrew,apt-repo', 'comma list of ACTIVE routes (parked: routes/later/)')
    }
    definition { cps { script(pipe('Jenkinsfile.publish')); sandbox(true) } }
}

// ci-7: the throwaway-isle job. Preflight FIRST (the device must be clear and
// have room), then up → verify → down. Manual only — nothing polls it, and the
// deb-install cycle inside the guest is ci-3.
pipelineJob('polari-isle-test') {
    description('ci-7b: preflight the device, then run every CI_ISLE_STAGES stage in its OWN throwaway isle (up → install core + that stage\'s app debs → selftest each → record → down), sequentially. Writes pool/<VERSION>/isle-test/results.json — THE file the release rule reads: only what a stage passed is ever published.')
    logRotator { numToKeep(20) }
    parameters { stringParam('VERSION', '', 'the pool version under test (empty = a bare device proof; no results recorded against a release)') }
    definition { cps { script(pipe('Jenkinsfile.isle-test')); sandbox(true) } }
}
