import { BottomBar, Slide } from '@deckio/deck-engine'
import styles from './EnvironmentSetupSlide.module.css'

export default function EnvironmentSetupSlide({ index, project }) {
  return (
    <Slide index={index} className={styles.environmentSetup}>
      <div className="accent-bar" />
      <div className={`orb ${styles.orb1}`} />
      <div className={`orb ${styles.orb2}`} />

      <div className={`${styles.body} content-frame content-gutter`}>
        <div className={styles.header}>
          <p className={styles.eyebrow}>Step 1</p>
          <h2>Environment <span className={styles.highlight}>Setup</span></h2>
          <p className={styles.subtitle}>
            Three commands to provision the full workshop lab
          </p>
        </div>

        <div className={styles.steps}>
          <div className={styles.step}>
            <div className={styles.stepNumber}>1</div>
            <div className={styles.stepContent}>
              <h3 className={styles.stepTitle}>Sign in to Azure</h3>
              <p className={styles.stepDesc}>
                Authenticate with your Azure account using the CLI
              </p>
              <code className={styles.code}>az login</code>
            </div>
          </div>

          <div className={styles.step}>
            <div className={styles.stepNumber}>2</div>
            <div className={styles.stepContent}>
              <h3 className={styles.stepTitle}>Select a subscription</h3>
              <p className={styles.stepDesc}>
                Set the target subscription for all subsequent commands
              </p>
              <code className={styles.code}>
                az account set --subscription &lt;subscription-id&gt;
              </code>
            </div>
          </div>

          <div className={styles.step}>
            <div className={styles.stepNumber}>3</div>
            <div className={styles.stepContent}>
              <h3 className={styles.stepTitle}>Run the setup script</h3>
              <p className={styles.stepDesc}>
                Deploys the DC VM, Hyper-V networking, ADDS, Azure Migrate appliance, and workload VMs
              </p>
              <code className={styles.code}>./prep-workshop-environment.ps1</code>
              <p className={styles.timing}>⏱ Takes ~40 minutes to fully deploy</p>
            </div>
          </div>
        </div>

        <div className={styles.resources}>
          <p className={styles.resourcesLabel}>What gets deployed</p>
          <div className={styles.tags}>
            <span className={styles.tag}>DC VM + Hyper-V</span>
            <span className={styles.tag}>ADDS / DNS Server</span>
            <span className={styles.tag}>Azure Migrate Appliance</span>
            <span className={styles.tag}>Ubuntu Webapp VM</span>
            <span className={styles.tag}>Ubuntu 24.04 VM</span>
          </div>
        </div>
      </div>

      <BottomBar text="azure-migrate-workshop" />
    </Slide>
  )
}
