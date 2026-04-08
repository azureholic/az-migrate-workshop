import { BottomBar, Slide } from '@deckio/deck-engine'
import styles from './BusinessCaseSlide.module.css'

export default function BusinessCaseSlide({ index, project }) {
  return (
    <Slide index={index} className={styles.businessCase}>
      <div className="accent-bar" />
      <div className={`orb ${styles.orb1}`} />
      <div className={`orb ${styles.orb2}`} />

      <div className={`${styles.body} content-frame content-gutter`}>
        <div className={styles.header}>
          <p className={styles.eyebrow}>Step 13</p>
          <h2>Review Inventory &amp; Build <span className={styles.highlight}>Business Case</span></h2>
          <p className={styles.subtitle}>
            Review your discovered inventory in the Azure Portal and generate a business case before migrating
          </p>
        </div>

        <div className={styles.columns}>
          <div className={styles.left}>
            <div className={styles.inventory}>
              <h3 className={styles.sectionTitle}>Your Inventory</h3>
              <div className={styles.stats}>
                <div className={styles.stat}>
                  <span className={styles.statNumber}>4</span>
                  <span className={styles.statLabel}>Machines</span>
                </div>
                <div className={styles.stat}>
                  <span className={styles.statNumber}>5</span>
                  <span className={styles.statLabel}>Workloads</span>
                </div>
              </div>
            </div>

            <div className={styles.instructions}>
              <p>We're going to perform several migrations, starting with a <strong>lift and shift</strong>. But first, build a business case.</p>
              <p>You can either use the <strong>Migration Agent</strong> or <strong>Generate a business case</strong> manually.</p>
            </div>

            <div className={styles.callout}>
              <strong>Important:</strong> Do not select the az-migrate appliance — we're not going to migrate that one.
            </div>
          </div>

          <div className={styles.right}>
            <img
              src="/BusinessCase.png"
              alt="Azure Portal — Build Business Case"
              className={styles.screenshot}
            />
          </div>
        </div>
      </div>

      <BottomBar text="azure-migrate-workshop" />
    </Slide>
  )
}
