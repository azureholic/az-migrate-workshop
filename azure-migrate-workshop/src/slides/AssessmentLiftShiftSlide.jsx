import { BottomBar, Slide } from '@deckio/deck-engine'
import styles from './AssessmentLiftShiftSlide.module.css'

export default function AssessmentLiftShiftSlide({ index, project }) {
  return (
    <Slide index={index} className={styles.assessmentLiftShift}>
      <div className="accent-bar" />
      <div className={`orb ${styles.orb1}`} />
      <div className={`orb ${styles.orb2}`} />

      <div className={`${styles.body} content-frame content-gutter`}>
        <div className={styles.header}>
          <p className={styles.eyebrow}>Step 19</p>
          <h2>Create Assessment — <span className={styles.highlight}>Lift &amp; Shift</span></h2>
          <p className={styles.subtitle}>
            Create a dedicated assessment for the UbuntuVM lift-and-shift migration
          </p>
        </div>

        <div className={styles.columns}>
          <div className={styles.left}>
            <div className={styles.instructions}>
              <p>Feel free to explore the assessment that the business case created.</p>
              <p>We can also add assessments for <strong>specific workloads</strong>. Let's create one for the <strong>UbuntuVM</strong> — which will be a lift-and-shift migration.</p>
            </div>
          </div>

          <div className={styles.right}>
            <img
              src="/CreateAssessment-LiftAndShift.png"
              alt="Create Assessment — Lift and Shift"
              className={styles.screenshot}
            />
          </div>
        </div>
      </div>

      <BottomBar text="azure-migrate-workshop" />
    </Slide>
  )
}
