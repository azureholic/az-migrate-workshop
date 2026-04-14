import { BottomBar, Slide } from '@deckio/deck-engine'
import styles from './HyperVHostCredentialsSlide.module.css'

export default function HyperVHostCredentialsSlide({ index, project }) {
  return (
    <Slide index={index} className={styles.hyperVHostCredentials}>
      <div className="accent-bar" />
      <div className={`orb ${styles.orb1}`} />
      <div className={`orb ${styles.orb2}`} />

      <div className={`${styles.body} content-frame content-gutter`}>
        <div className={styles.header}>
          <p className={styles.eyebrow}>Step 6</p>
          <h2>HyperV Host <span className={styles.highlight}>Credentials</span></h2>
          <p className={styles.subtitle}>
            Add the Hyper-V host credentials so the appliance can discover your environment
          </p>
        </div>

        <div className={styles.columns}>
          <div className={styles.left}>
            <h3 className={styles.sectionTitle}>Add Credential</h3>

            <div className={styles.fieldGroup}>
              <div className={styles.field}>
                <span className={styles.fieldLabel}>Source Type</span>
                <span className={styles.fieldValue}>Hyper-V Host/Cluster</span>
              </div>
              <div className={styles.field}>
                <span className={styles.fieldLabel}>Friendly Name</span>
                <span className={styles.fieldValue}>Datacenter</span>
              </div>
              <div className={styles.field}>
                <span className={styles.fieldLabel}>Username</span>
                <span className={styles.fieldValue}>azureuser</span>
              </div>
            </div>
          </div>

          <div className={styles.right}>
            <img
              src="/Hyperv-Host-Credentials.png"
              alt="Hyper-V Host Credentials configuration"
              className={styles.screenshot}
            />
          </div>
        </div>
      </div>

      <BottomBar text="azure-migrate-workshop" />
    </Slide>
  )
}
