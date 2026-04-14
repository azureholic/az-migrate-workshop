import { BottomBar, Slide } from '@deckio/deck-engine'
import styles from './MigrateLiftShiftSlide.module.css'

export default function MigrateLiftShiftSlide({ index, project }) {
  return (
    <Slide index={index} className={styles.migrateLiftShift}>
      <div className="accent-bar" />
      <div className={`orb ${styles.orb1}`} />
      <div className={`orb ${styles.orb2}`} />

      <div className={`${styles.body} content-frame content-gutter`}>
        <div className={styles.header}>
          <p className={styles.eyebrow}>Step 28</p>
          <h2>Migrate — <span className={styles.highlight}>Lift &amp; Shift</span></h2>
          <p className={styles.subtitle}>
            Test and complete the migration using Azure Site Recovery
          </p>
        </div>

        <div className={styles.columns}>
          <div className={styles.left}>
            <div className={styles.instructions}>
              <p>After that you can do a <strong>test migration</strong> (this will not affect the original machine) and eventually a <strong>final migration</strong> if the test is successful — this will stop the Hyper-V VM.</p>
              <p>Choose <strong>Testing → Start test migration</strong></p>
              <p>If succeeded, choose <strong>Testing → Cleanup test migration</strong></p>
              <p>Then choose <strong>Completion → Migrate</strong></p>
              <p><strong>⚠️ WARNING:</strong> Do NOT use a reservation (this is specific to this workshop).</p>
              <p>You have now successfully migrated a Hyper-V VM to Azure using Azure Site Recovery.</p>
            </div>
          </div>

          <div className={styles.right}>
            <img
              src="/Migrate-LiftandShift.png"
              alt="Migrate — Lift and Shift"
              className={styles.screenshot}
            />
          </div>
        </div>
      </div>

      <BottomBar text="azure-migrate-workshop" />
    </Slide>
  )
}
