import { BottomBar, Slide } from '@deckio/deck-engine'
import styles from './WindowsUpdateSlide.module.css'

export default function WindowsUpdateSlide({ index, project }) {
  return (
    <Slide index={index} className={styles.windowsUpdate}>
      <div className="accent-bar" />
      <div className={`orb ${styles.orb1}`} />
      <div className={`orb ${styles.orb2}`} />

      <div className={`${styles.body} content-frame content-gutter`}>
        <div className={styles.header}>
          <p className={styles.eyebrow}>Step 4</p>
          <h2>Run <span className={styles.highlight}>Windows Update</span></h2>
          <p className={styles.subtitle}>
            Make sure the appliance VM has the latest updates before configuring prerequisites
          </p>
        </div>

        <div className={styles.card}>
          <div className={styles.stepNumber}>!</div>
          <div className={styles.cardContent}>
            <h3 className={styles.cardTitle}>Update the appliance VM</h3>
            <p className={styles.cardDesc}>
              Inside the appliance VM, open <strong>Settings → Windows Update</strong> and install all available updates. Restart the VM if prompted, then reconnect before continuing.
            </p>
            <p className={styles.hint}>
              You can check the status in the DC VM's <strong>Hyper-V Manager</strong> to make sure the appliance has finished updating.
            </p>
          </div>
        </div>
      </div>

      <BottomBar text="azure-migrate-workshop" />
    </Slide>
  )
}
