import { BottomBar, Slide } from '@deckio/deck-engine'
import styles from './FinalizeRegistrationSlide.module.css'

export default function FinalizeRegistrationSlide({ index, project }) {
  return (
    <Slide index={index} className={styles.finalizeRegistration}>
      <div className="accent-bar" />
      <div className={`orb ${styles.orb1}`} />
      <div className={`orb ${styles.orb2}`} />

      <div className={`${styles.body} content-frame content-gutter`}>
        <div className={styles.header}>
          <p className={styles.eyebrow}>Step 26</p>
          <h2>Finalize <span className={styles.highlight}>Registration</span></h2>
          <p className={styles.subtitle}>
            Confirm the registered Hyper-V hosts and proceed
          </p>
        </div>

        <div className={styles.columns}>
          <div className={styles.left}>
            <div className={styles.instructions}>
              <p>Verify that the Hyper-V host is now registered successfully.</p>
              <p>Click the <strong>Finalize Registration</strong> button to proceed.</p>
              <p>Wait for the message that the status is: <strong>Registration finalized</strong>.</p>
            </div>
          </div>

          <div className={styles.right}>
            <img
              src="/RegisteredHyperVHosts.png"
              alt="Registered Hyper-V Hosts"
              className={styles.screenshot}
            />
          </div>
        </div>
      </div>

      <BottomBar text="azure-migrate-workshop" />
    </Slide>
  )
}
