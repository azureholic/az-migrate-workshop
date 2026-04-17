import { BottomBar, Slide } from '@deckio/deck-engine'
import styles from './AzureLoginSlide.module.css'

export default function AzureLoginSlide({ index, project }) {
  return (
    <Slide index={index} className={styles.azureLogin}>
      <div className="accent-bar" />
      <div className={`orb ${styles.orb1}`} />
      <div className={`orb ${styles.orb2}`} />

      <div className={`${styles.body} content-frame content-gutter`}>
        <div className={styles.header}>
          <p className={styles.eyebrow}>Prerequisites</p>
          <h2>Login to <span className={styles.highlight}>Azure</span></h2>
          <p className={styles.subtitle}>
            Install the Bastion CLI extension and authenticate with your Azure subscription
          </p>
        </div>

        <div className={styles.steps}>
          <div className={styles.step}>
            <div className={styles.stepNumber}>1</div>
            <div className={styles.stepContent}>
              <h3 className={styles.stepTitle}>Add the Bastion extension</h3>
              <p className={styles.stepDesc}>
                Install the Azure Bastion extension for the Azure CLI — required for tunneling into VMs later
              </p>
              <code className={styles.code}>az extension add --name bastion</code>
            </div>
          </div>

          <div className={styles.step}>
            <div className={styles.stepNumber}>2</div>
            <div className={styles.stepContent}>
              <h3 className={styles.stepTitle}>Sign in to Azure</h3>
              <p className={styles.stepDesc}>
                Authenticate with your Azure account using the CLI
              </p>
              <code className={styles.code}>az login</code>
            </div>
          </div>

          <div className={styles.step}>
            <div className={styles.stepNumber}>3</div>
            <div className={styles.stepContent}>
              <h3 className={styles.stepTitle}>Select a subscription</h3>
              <p className={styles.stepDesc}>
                Set the target subscription for all subsequent commands
              </p>
              <code className={styles.code}>
                az account set --subscription "&lt;subscription-id&gt;"
              </code>
            </div>
          </div>
        </div>

        <div className={styles.note}>
          <span className={styles.noteIcon}>ℹ️</span>
          <p className={styles.noteText}>
            Your account must have <strong>Owner</strong> role on the subscription
          </p>
        </div>

        <div className={styles.note}>
          <span className={styles.noteIcon}>🛠️</span>
          <p className={styles.noteText}>
            Please check the prerequisites on{' '}
            <a
              href="https://github.com/azureholic/az-migrate-workshop/blob/main/workshop/prereq.md"
              target="_blank"
              rel="noopener noreferrer"
              className={styles.link}
            >
              prereq.md
            </a>{' '}
            before you start the workshop. If you need to provision the workshop environment, follow those instructions.
          </p>
        </div>
      </div>

      <BottomBar text="azure-migrate-workshop" />
    </Slide>
  )
}
