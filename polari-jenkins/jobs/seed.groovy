// Job DSL seed (loaded by Configuration as Code on every boot — jobs are
// code, never clicked together).
//
// ci-12 — THE BRANCH MODEL (his ruling 2026-09-19): dev → test → main, and the
// two pipelines that ride it.
//
//   dev   polari-dev-build   an OPTIONAL quick build. No tests, no scans, no
//                            publish. It exists so a dev push still tells you
//                            "it compiles", nothing more.
//   test  polari-test        the TESTING pipeline: wipe → build → scan → test →
//                            ONE verdict per sha. Publishes nothing, ever.
//   main  polari-release     the RELEASE pipeline: build the artifacts and hand
//                            them to polari-publish — and ONLY for a sha whose
//                            test verdict is `passed`. It re-runs no test; it
//                            reads the verdict the test run recorded.
//
// THE QUEUE (his addendum, same day: "We should not be endlessly queuing jobs …
// if multiple changes come in we just keep putting off testing and do the LAST
// one that came in for that queue.").
//
//   · quietPeriod(300) — five minutes. Every further change detected inside the
//     window RESTARTS it, so a promotion that pushes ten repos produces ONE run.
//   · NOT PARAMETERISED. Jenkins coalesces queued items of a non-parameterised
//     job into one; two parameterised items with different values would both
//     sit in the queue and both run. That is why polari-release no longer takes
//     VERSION or BUILD_OFFLINE_MEDIUM as build parameters: the version is minted
//     INSIDE the run (mint-tag.sh) and the offline medium is a device knob
//     (CI_BUILD_OFFLINE_MEDIUM). polari-release-manual keeps the parameters for
//     the rare hand-driven case, and nothing polls it.
//   · quiet.sh is the belt to that braces: pool/queue/<branch>.json holds AT
//     MOST ONE pending item, it always means "the newest state of the branch",
//     and the run's first stage re-checks the whole forest and DEFERS (NOT_BUILT)
//     rather than building a promotion that is still landing.
//
// TWO QUEUES, NEVER CONCURRENT, ALTERNATING. test and main are separate jobs, so
// separate queues. Both take the `polari-build` lockable resource, so they never
// run at once. The Lockable Resources plugin grants waiting builds in FIFO
// order, which already alternates them under a steady stream; quiet.sh's turn
// marker is the guard for the case FIFO cannot cover — a job that re-queues
// faster than the other gets its turn yields the build (NOT_BUILT, pending item
// intact) instead of sleeping on the lock.
def repo = 'https://github.com/dausume/polari-suite.git'
def pipe = { name -> new File("/var/polari-jenkins/pipelines/${name}").text }  // JCasC runs the DSL without a workspace

pipelineJob('polari-dev-build') {
    description('''dev — the OPTIONAL quick build. Polls dev every 10 min; recursive-ish checkout; builds debs (both flavors) + images. \
NO isle tests, NO scans, NO publish — ci-12 moved all of those to polari-test. A green dev-build means "it built", and that is all it means.''')
    logRotator { numToKeep(5); artifactNumToKeep(2) }   // dev artifacts: two builds' debs, no more
    triggers { scm('H/10 * * * *') }
    quietPeriod(300)                                    // ci-12: five quiet minutes across the forest
    definition { cps { script(pipe('Jenkinsfile.dev-build')); sandbox(true) } }
}

// ci-12 — THE TESTING PIPELINE. His words: "Pushing our dev work to test will
// kick off the process of wiping what we have locally and then running all of
// our tests and scans."
pipelineJob('polari-test') {
    description('''test — THE TESTING PIPELINE (ci-12). Polls test every 5 min. Wipes this device's state, builds the debs and images, \
runs the ADVISORY scans (Trivy + gitleaks + pip-audit + npm audit — no finding gates anything), runs every configured module selftest in the \
built backend image, runs the throwaway-isle stages, and records ONE verdict per sha at pool/test/&lt;sha&gt;/verdict.json. \
PUBLISHES NOTHING. The job is SUCCESS when it ran to the end — a failed test is a recorded VERDICT, not a red build; it is FAILURE only when a \
stage could not run. pol jenkins test-status &lt;sha&gt; prints the verdict; pol jenkins promote main refuses anything but `passed`.''')
    logRotator { numToKeep(20); artifactNumToKeep(10) }
    // ci-12: a PERIODIC tick, not an SCM trigger. Jenkins' SCM trigger fires on a
    // CHANGE, so a run that defers because the change is still landing would never
    // be retried — by the time the forest IS quiet, nothing has changed again.
    // (That is what build #1 on the pipeline device did.) The tick is made cheap
    // by `quiet.sh gate`: one ls-remote of the superproject before any checkout,
    // which answers "is there anything here that is not already tested?" in a
    // second. quietPeriod still coalesces the ticks into one queued item.
    triggers { cron('H/5 * * * *') }
    // NO quietPeriod here. Jenkins' quiet period delays the queued item by five
    // minutes ON TOP of the tick, and quiet.sh already owns the five-minute
    // forest window — the two stacked would make the shortest path from a push
    // to a verdict ten minutes for no gain. Coalescing does not need it either:
    // Jenkins merges queued items of a NON-PARAMETERISED job on its own, which
    // is why this job takes no parameters.
    // NO parameters, deliberately: Jenkins coalesces queued items of a
    // non-parameterised job, so ten pushes in five minutes are ONE queued run.
    definition { cps { script(pipe('Jenkinsfile.test')); sandbox(true) } }
}

pipelineJob('polari-release') {
    description('''main — THE RELEASE PIPELINE (ci-12). Polls main every 10 min; mints the version INSIDE the run; builds everything + \
release.json + the offline medium into pool/&lt;version&gt;/ and triggers polari-publish with DRY_RUN=auto. \
It runs NO tests: the release rule now reads the TEST verdict recorded for this sha (pool/test/&lt;sha&gt;/verdict.json must say `passed`), \
and every route stays DRY without one. Not parameterised, so the poll queue can never hold more than one item.''')
    logRotator { numToKeep(10); artifactNumToKeep(3) }  // the pool itself is pruned by retention.sh (POOL_KEEP)
    triggers { cron('H/10 * * * *') }     // periodic, for the same reason polari-test is — see above
    // no quietPeriod, for the same reason: quiet.sh owns the window.
    definition { cps { script(pipe('Jenkinsfile.release')); sandbox(true) } }
}

// The hand-driven twin of polari-release, for the rare case somebody needs to
// build a specific shape by hand. NOTHING POLLS IT, so its parameters can never
// produce a queue of distinct items.
pipelineJob('polari-release-manual') {
    description('ci-12: polari-release, by hand, with the two knobs exposed. Nothing polls this job — the poll path is polari-release, which takes no parameters so its queue coalesces.')
    logRotator { numToKeep(10) }
    parameters {
        booleanParam('BUILD_OFFLINE_MEDIUM', true, 'assemble offline-build/<version>/ (2 GB, minutes)')
        booleanParam('FORCE_UNTESTED', false, 'build even though the sha has no passed test verdict — the routes still refuse to publish it (the release rule is hard)')
    }
    definition { cps { script(pipe('Jenkinsfile.release')); sandbox(true) } }
}

pipelineJob('polari-publish') {
    description('ci-6: publish pool/<VERSION>/ to the selected routes. DRY_RUN=true renders every command and pushes nothing. Triggered by polari-release; nothing polls it.')
    logRotator { numToKeep(50) }
    parameters {
        stringParam('VERSION', '', 'polari version under pool/ (e.g. 2026.09.07-dev+7d6db81)')
        // ci-7 (C): auto = publish for real only where the secret is present AND the route is in CI_ROUTES
        choiceParam('DRY_RUN', ['auto', 'true', 'false'], 'auto (default): armed per route by secret + CI_ROUTES · true: render only · false: force a real push')
        stringParam('ROUTES', 'github-release,ghcr,homebrew,apt-repo', 'comma list of ACTIVE routes (parked: routes/later/)')
    }
    definition { cps { script(pipe('Jenkinsfile.publish')); sandbox(true) } }
}

// dep-2 (plan §11): PRODUCTION AS THE STEP AFTER PUBLISH. One stage per deployment
// target; deploy/conditions.sh says GO or SKIP with every condition's evidence;
// GO → deploy/apply.sh over ssh as the pipeline user. Triggered by polari-publish
// on success, and polled every ten minutes (a closed window or a lifted hold is
// picked up without a new release). A SKIP is NOT_BUILT; FAILURE only when an
// attempted deploy failed (then rule 4: it waits for a newer release or a person).
pipelineJob('polari-deploy') {
    description('dep-2: deploy the published release to every DEPLOYMENT TARGET whose conditions all hold (newer · tested · published for real · window · healthy · disk · idle · hold off · not failed) — over ssh as the pipeline user, `pol prod apply` + verify + health, rollback by re-pin. Triggered by polari-publish; also polls every 10 min for targets whose window or hold changed. pol jenkins deploy list|check|status.')
    logRotator { numToKeep(50) }
    parameters { stringParam('VERSION', '', 'the release to deploy (empty = the newest in the pool)') }
    triggers { cron('H/10 * * * *') }
    definition { cps { script(pipe('Jenkinsfile.deploy')); sandbox(true) } }
}

// ci-7: the throwaway-isle job. Preflight FIRST (the device must be clear and
// have room), then per stage: up → install + test (ci-3) → uninstall → down →
// leakcheck. ci-12: it is triggered by polari-test, and stays available as a
// manual tool; polari-release no longer triggers it (the release reads the test
// verdict instead of re-running the tests).
pipelineJob('polari-isle-test') {
    description('''ci-7b/ci-12: preflight the device, then run every CI_ISLE_STAGES stage in its OWN throwaway isle (up → install core + that stage\'s app debs → selftest each → the product\'s own uninstall → down → leak check), sequentially. \
Writes pool/&lt;VERSION&gt;/isle-test/results.json — which the TEST verdict reads. Triggered by polari-test with VERSION=test/&lt;sha&gt;; also runnable by hand. It locks `polari-isle-target`, not `polari-build`, because its caller already holds the build lock.''')
    logRotator { numToKeep(20) }
    parameters { stringParam('VERSION', '', 'the pool version under test (empty = a bare device proof; no results recorded against a release)') }
    definition { cps { script(pipe('Jenkinsfile.isle-test')); sandbox(true) } }
}
