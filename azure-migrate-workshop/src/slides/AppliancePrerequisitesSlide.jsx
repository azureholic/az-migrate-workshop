import { BottomBar, Slide } from '@deckio/deck-engine'
import styles from './AppliancePrerequisitesSlide.module.css'

export default function AppliancePrerequisitesSlide({ index, project }) {
  return (
    <Slide index={index} className={styles.appliancePrereqs}>
      <div className="accent-bar" />
      <div className={`orb ${styles.orb1}`} />
      <div className={`orb ${styles.orb2}`} />

      <div className={`${styles.body} content-frame content-gutter`}>
        <div className={styles.header}>
          <p className={styles.eyebrow}>Step 5</p>
          <h2>Configure Appliance: <span className={styles.highlight}>Update &amp; Register</span></h2>
          <p className={styles.subtitle}>
            Paste the project key, let the appliance update, and sign in to Azure
          </p>
        </div>

        <div className={styles.columns}>
          <div className={styles.left}>
            <div className={styles.step}>
              <div className={styles.stepNumber}>1</div>
              <div className={styles.stepContent}>
                <h3 className={styles.stepTitle}>Paste the project key</h3>
                <p className={styles.stepDesc}>
                  Open the appliance configuration manager and paste the <strong>Azure Migrate project key</strong> you copied earlier, then click <strong>Verify</strong>
                </p>
              </div>
            </div>

            <div className={styles.step}>
              <div className={styles.stepNumber}>2</div>
              <div className={styles.stepContent}>
                <h3 className={styles.stepTitle}>Wait for auto-update</h3>
                <p className={styles.stepDesc}>
                  The appliance installs the latest updates automatically — this takes a couple of minutes. The browser will refresh on its own when done.
                </p>
              </div>
            </div>

            <div className={styles.step}>
              <div className={styles.stepNumber}>3</div>
              <div className={styles.stepContent}>
                <h3 className={styles.stepTitle}>Login to Azure</h3>
                <p className={styles.stepDesc}>
                  Click <strong>Login</strong>, enter your Azure account credentials, and wait for the appliance registration to complete
                </p>
              </div>
            </div>
          </div>

          <div className={styles.right}>
            <img
              src="/appliance-prerequisites.png"
              alt="Appliance configuration manager — set up prerequisites"
              className={styles.screenshot}
            />
          </div>
        </div>
      </div>

      <BottomBar text="azure-migrate-workshop" />
    </Slide>
  )
}
