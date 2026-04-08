import { BottomBar, Slide } from '@deckio/deck-engine'
import styles from './ConnectApplianceRdpSlide.module.css'

export default function ConnectApplianceRdpSlide({ index, project }) {
  return (
    <Slide index={index} className={styles.connectApplianceRdp}>
      <div className="accent-bar" />
      <div className={`orb ${styles.orb1}`} />
      <div className={`orb ${styles.orb2}`} />

      <div className={`${styles.body} content-frame content-gutter`}>
        <div className={styles.header}>
          <p className={styles.eyebrow}>Step 3</p>
          <h2>Connect to the <span className={styles.highlight}>Appliance</span></h2>
          <p className={styles.subtitle}>
            Open an RDP session to the Azure Migrate appliance
          </p>
        </div>

        <div className={styles.content}>
          <div className={styles.instructions}>
            <p>Run the tunnel script to create an RDP session to the appliance:</p>
            <code className={styles.code}>./tunnel-appl.ps1</code>
            <p>A tunnel will be created in a new terminal window. <strong>Don't close this window</strong> (you can minimize it).</p>
            <p>Use the password you've set for the appliance machine, the user is <strong>Administrator</strong>.</p>
          </div>
        </div>
      </div>

      <BottomBar text="azure-migrate-workshop" />
    </Slide>
  )
}
