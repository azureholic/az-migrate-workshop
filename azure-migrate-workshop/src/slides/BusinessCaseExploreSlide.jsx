import { BottomBar, Slide } from '@deckio/deck-engine'
import styles from './BusinessCaseExploreSlide.module.css'

export default function BusinessCaseExploreSlide({ index, project }) {
  return (
    <Slide index={index} className={styles.businessCaseExplore}>
      <div className="accent-bar" />
      <div className={`orb ${styles.orb1}`} />
      <div className={`orb ${styles.orb2}`} />

      <div className={`${styles.body} content-frame content-gutter`}>
        <div className={styles.header}>
          <p className={styles.eyebrow}>Step 18</p>
          <h2>Explore <span className={styles.highlight}>Business Case</span></h2>
          <p className={styles.subtitle}>
            Review the outcome of your business case assessment
          </p>
        </div>

        <div className={styles.columns}>
          <div className={styles.left}>
            <div className={styles.instructions}>
              <p>Once the business case has been generated, explore the results.</p>
              <p>Review the <strong>cost comparison</strong>, projected savings, and migration readiness for your selected workloads.</p>
            </div>
          </div>

          <div className={styles.right}>
            <img
              src="/BusinessCaseExplore.png"
              alt="Business Case Explore — outcome overview"
              className={styles.screenshot}
            />
          </div>
        </div>
      </div>

      <BottomBar text="azure-migrate-workshop" />
    </Slide>
  )
}
