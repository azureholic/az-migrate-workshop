import { BottomBar, Slide } from '@deckio/deck-engine'
import styles from './ConfigureApplianceSlide.module.css'

export default function ConfigureApplianceSlide({ index, project }) {
  return (
    <Slide index={index} className={styles.configureAppliance}>
      <div className="accent-bar" />
      <div className={`orb ${styles.orb1}`} />
      <div className={`orb ${styles.orb2}`} />

      <div className={`${styles.body} content-frame content-gutter`}>
        <div className={styles.header}>
          <p className={styles.eyebrow}>Step 2</p>
          <h2>Configure Appliance: <span className={styles.highlight}>Setup Prerequisites</span></h2>
          <p className={styles.subtitle}>
            Generate the appliance key in the Azure Portal before configuring the appliance
          </p>
        </div>

        <div className={styles.columns}>
          <div className={styles.left}>
            <div className={styles.step}>
              <div className={styles.stepNumber}>1</div>
              <div className={styles.stepContent}>
                <h3 className={styles.stepTitle}>Open the Azure Portal on the DC VM</h3>
                <p className={styles.stepDesc}>
                  Inside the RDP session, open a browser and navigate to <strong>portal.azure.com</strong>
                </p>
              </div>
            </div>

            <div className={styles.step}>
              <div className={styles.stepNumber}>2</div>
              <div className={styles.stepContent}>
                <h3 className={styles.stepTitle}>Find the Azure Migrate project</h3>
                <p className={styles.stepDesc}>
                  Go to resource group <strong>rg-migrate-workshop</strong> and open the Azure Migrate project
                </p>
              </div>
            </div>

            <div className={styles.step}>
              <div className={styles.stepNumber}>3</div>
              <div className={styles.stepContent}>
                <h3 className={styles.stepTitle}>Generate the project key</h3>
                <ul className={styles.list}>
                  <li>Click <strong>Discover</strong> on the Overview page</li>
                  <li>Select <strong>Using appliance</strong> for Azure</li>
                  <li>Choose <strong>Yes, with Hyper-V</strong></li>
                  <li>Name the appliance: <strong>az-migrate</strong></li>
                  <li>Click <strong>Generate Key</strong> and copy it</li>
                </ul>
              </div>
            </div>
          </div>

          <div className={styles.right}>
            <img
              src="/discover-key.png"
              alt="Azure Migrate Discover — generate project key"
              className={styles.screenshot}
            />
          </div>
        </div>
      </div>

      <BottomBar text="azure-migrate-workshop" />
    </Slide>
  )
}
