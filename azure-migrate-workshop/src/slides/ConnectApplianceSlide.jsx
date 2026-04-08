import { BottomBar, Slide } from '@deckio/deck-engine'
import styles from './ConnectApplianceSlide.module.css'

export default function ConnectApplianceSlide({ index, project }) {
  return (
    <Slide index={index} className={styles.connectAppliance}>
      <div className="accent-bar" />
      <div className={`orb ${styles.orb1}`} />
      <div className={`orb ${styles.orb2}`} />

      <div className={`${styles.body} content-frame content-gutter`}>
        <div className={styles.header}>
          <p className={styles.eyebrow}>Step 2</p>
          <h2>Prepare the <span className={styles.highlight}>Appliance</span></h2>
          <p className={styles.subtitle}>
            Tunnel into the DC VM and access the Azure Migrate appliance via Hyper-V
          </p>
        </div>

        <div className={styles.steps}>
          <div className={styles.step}>
            <div className={styles.stepNumber}>1</div>
            <div className={styles.stepContent}>
              <h3 className={styles.stepTitle}>Open a Bastion tunnel</h3>
              <p className={styles.stepDesc}>
                Creates an RDP tunnel through Azure Bastion and launches a remote-desktop session to the DC VM
              </p>
              <code className={styles.code}>./tunnel-dc.ps1</code>
              <p className={styles.hint}>
                A new terminal window opens for the tunnel — <strong>do not close it</strong>. The VM password is copied to your clipboard — paste with Ctrl+V at the RDP prompt.
              </p>
            </div>
          </div>

          <div className={styles.step}>
            <div className={styles.stepNumber}>2</div>
            <div className={styles.stepContent}>
              <h3 className={styles.stepTitle}>Open Hyper-V Manager</h3>
              <p className={styles.stepDesc}>
                Inside the RDP session, launch Hyper-V Manager from the Start menu or taskbar
              </p>
            </div>
          </div>

          <div className={styles.step}>
            <div className={styles.stepNumber}>3</div>
            <div className={styles.stepContent}>
              <h3 className={styles.stepTitle}>Connect to the appliance</h3>
              <p className={styles.stepDesc}>
                Right-click the Azure Migrate appliance VM and select <strong>Connect</strong>
              </p>
            </div>
          </div>

          <div className={styles.step}>
            <div className={styles.stepNumber}>4</div>
            <div className={styles.stepContent}>
              <h3 className={styles.stepTitle}>Set password on the appliance</h3>
              <p className={styles.stepDesc}>
                On first boot the appliance prompts you to set an administrator password — choose a strong one and note it down
              </p>
              <p className={styles.hint}>
                After setting the password, close the appliance connection — but <strong>keep the RDP session to the DC VM open</strong>, you will need it later.
              </p>
            </div>
          </div>
        </div>
      </div>

      <BottomBar text="azure-migrate-workshop" />
    </Slide>
  )
}
