import { BottomBar, Slide } from '@deckio/deck-engine'
import styles from './ReviewAssessmentLiftShiftSlide.module.css'

export default function ReviewAssessmentLiftShiftSlide({ index, project }) {
  return (
    <Slide index={index} className={styles.reviewAssessment}>
      <div className="accent-bar" />
      <div className={`orb ${styles.orb1}`} />
      <div className={`orb ${styles.orb2}`} />

      <div className={`${styles.body} content-frame content-gutter`}>
        <div className={styles.header}>
          <p className={styles.eyebrow}>Step 20</p>
          <h2>Review Assessment — <span className={styles.highlight}>Lift &amp; Shift</span></h2>
          <p className={styles.subtitle}>
            Explore the assessment for the UbuntuVM and create a migration wave
          </p>
        </div>

        <div className={styles.columns}>
          <div className={styles.left}>
            <div className={styles.instructions}>
              <p>Explore the assessment for this single VM and notice the difference. The assessment already decided that this workload is a <strong>lift-and-shift candidate</strong>.</p>
              <p>You can create a <strong>wave</strong> from this step to group the workload for migration.</p>
            </div>
          </div>

          <div className={styles.right}>
            <img
              src="/ReviewAssessment-LiftShift.png"
              alt="Review Assessment — Lift and Shift"
              className={styles.screenshot}
            />
          </div>
        </div>
      </div>

      <BottomBar text="azure-migrate-workshop" />
    </Slide>
  )
}
